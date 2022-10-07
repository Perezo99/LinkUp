const functions = require("firebase-functions");
const admin = require('firebase-admin');
const { error } = require("firebase-functions/logger");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onCreateFollowers = functions.firestore
  .document('/followers/{userId}/usersFollowers/{followerId}')
  .onCreate(async (snapshot, context) => {
       console.log('Follower created', snapshot.data());
       const userId = context.params.userId;
       const followerId = context.params.followerId;

    
    const followedUsersPostRef = admin
    .firestore()
    .collection('posts')
    .doc(userId)
    .collection('usersPosts');
    
    // get following users timeline
    const timelinePostsRef = admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts');

    // get followed users posts
     const querySnapshot = await followedUsersPostRef.get();

    // add posts too timeline
    querySnapshot.forEach(doc => {
        if (doc.exists) {
           const postId = doc.id;
           const postData = doc.data(); 
           timelinePostsRef.doc(postId).set(postData);
        }
    });

   });

   exports.onDeleteFollowers = functions.firestore
    .document('/followers/{userId}/usersFollowers/{followerId}')
    .onDelete(async (snapshot, context) => {
        console.log('Followers Deleted', snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const timelinePostsRef = admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .where('ownerId', '==', userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
           if (doc.exists) {
               doc.ref.delete;
           } 
        });
    })

    // add post too timeline of followers
    exports.onCreatePost = functions.firestore
    .document('/posts/{userId}/usersPosts/{postId}')
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
    

    // get all the followers of the user
     const usersFollowersRef = admin
     .firestore()
     .collection('followers')
     .doc(userId)
     .collection('usersFollowers');

     // add new post to each followers timeline
     querySnapshot.forEach(doc => {
         const followerId = doc.id;

         admin
          .firestore()
          .collection('timeline')
          .doc(followerId)
          .collection('timelinePosts')
          .doc(postId)
          .set(postCreated);
     })
    });

exports.onUpdatePost = functions.firestore
.document('/posts/{userId}/usersPosts/{postId}')
.onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //get all the followers of the users 
    const usersFollowersRef = admin
    .firestore()
    .collection('followers')
    .doc(userId)
    .collection('usersFollowers');

    const querySnapshot = await usersFollowersRef.get();

    //update each post on followers timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;

        admin
          .firestore()
          .collection('timeline')
          .doc(followerId)
          .collection('timelinePosts')
          .doc(postId)
          .get().then(doc => {
              if (doc.exists) {
                  doc.ref.update(postUpdated);
              }
          });
    })
})

exports.onDeletePost = functions.firestore
   .document('/posts/{userId}/usersPosts/{postId}')
   .onDelete(async (snapshot, context) => {
       const userId = context.params.userId;
       const postId = context.params.postId;

       //get all the followers of the users 
       const usersFollowersRef = admin
           .firestore()
           .collection('followers')
           .doc(userId)
           .collection('usersFollowers');

       const querySnapshot = await usersFollowersRef.get();

       //delete each post on followers timeline
       querySnapshot.forEach(doc => {
           const followerId = doc.id;

           admin
               .firestore()
               .collection('timeline')
               .doc(followerId)
               .collection('timelinePosts')
               .doc(postId)
               .get().then(doc => {
                   if (doc.exists) {
                       doc.ref.delete();
                   }
               });
       })
   })

exports.onCreateActivityFeedItem = functions.firestore
  .document('/feed/{userId}/feedItems/{activityFeedItem}')
  .onCreate(async (snapshot, context) => {
      console.log('Activity Feed Item Created', snapshot.data());
    
      //Get user connected to feed
      const userId = context.params.userId;
      const userRef = admin.firestore().doc(`users/${userId}`);

      const doc = await userRef.get();
     

      //check if user have a notification token and send if they do
      const androidNotificationToken = doc.data().androidNotificationToken;
      const activityFeedItem = snapshot.data();
      if (androidNotificationToken) {
          sendNotification(androidNotificationToken, activityFeedItem)
      } else {
          console.log('No Token for user, cannot send notification');
      }

      function sendNotification(androidNotificationToken, activityFeedItem){
          let body;

          //switch body value based of notification type
          switch (activityFeedItem.type) {
              case 'comment':
                  body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                  break;
              case 'like':
                  body = `${activityFeedItem.username} liked your post`;
              case 'follow':
                  body = `${activityFeedItem.username} started following you`;
              default:
                  break;
          }

          //create message for push notification
          const message = {
              notification: { body },
              token: androidNotificationToken,
              data: { recipient: userId}
          }

          //send message with admin messaging
          admin
            .messaging()
            .send(message)
            .then(response => {
                //response is a message ID string
                console.log('Successfully sent message', response)
            })
            .catch(error => {
                console.log('Error sending message', response)
            })
      }
  })