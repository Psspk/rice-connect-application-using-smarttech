const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();

// Function to set user as Admin
async function setAdmin(uid) {
  try {
    await auth.setCustomUserClaims(uid, { role: "admin" });
    console.log(`✅ Success: User ${uid} is now an admin.`);
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
  }
}

// Provide the User ID (UID) of the user you want to make an admin
const userId = "hCVUcfYV6jTiM4cu8VdcNuB6Aaz2"; // Replace this with actual UID

setAdmin(userId);
