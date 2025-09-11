const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require("razorpay");
const nodemailer = require('nodemailer');
const axios = require('axios')
const { Filter, FieldPath, FieldValue } = require('firebase-admin/firestore');
const { HttpsError, user } = require('firebase-functions/v1/auth');
admin.initializeApp();
//const fs = require("fs");
//
//
//
//// JSON file load karo
//const raw = fs.readFileSync("./balanced_users.json");
//let allUsers = JSON.parse(raw);


const transporter = nodemailer.createTransport({
  host: 'mail.dbvertex.com', // SMTP server
  port: 465,
  secure: true,
  auth: {
    user: "pradhaan@dbvertex.com",
    pass: "=9gM7j-0etns",
  },
});

// Email template
const emailTemplate = `
  <div style="font-family: Arial, sans-serif; line-height: 1.5; color: #333;">
    <div style="text-align: center; margin-bottom: 20px;">
      <img src="cid:pradhan_logo" alt="Pradhaan Logo" style="max-width: 150px;"/>
    </div>
    <h2 style="text-align: center; color: #444;">Pradhaan Meeting Invitation</h2>
    <p style="font-size: 16px; margin: 10px 0;"><strong>Date:</strong> {{meetingDate}}</p>
    <p style="font-size: 16px; margin: 10px 0;"><strong>Time:</strong> {{meetingTime}}</p>
    <p style="font-size: 16px; margin: 10px 0;"><strong>Address:</strong> {{meetingAddress}}</p>
    <div style="display: flex; align-items: center; margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 8px;">
      <img src="cid:pradhan_dp" alt="Pradhaan DP" style="border-radius: 50%; width: 50px; height: 50px; margin-right: 15px;"/>
      <div>
        <p style="font-size: 16px; margin: 0;"><strong>{{pradhaan.name}}</strong> says:</p>
        <p style="font-size: 16px; margin: 5px 0; color: #555;">"{{customMessage}}"</p>
      </div>
    </div>
    <footer style="margin-top: 30px; text-align: center; font-size: 12px; color: #999;">
      <p>Powered by Pradhaan | © 2024</p>
    </footer>
  </div>
`;

exports.sendMail = functions.https.onCall(async (data, context) => {
  const { scope_suffix, message, videoUrl, receivers } = data;

  // Temp log
  const logger_logs = [];
  const logger = (msg) => {
    logger_logs.push(msg);
  };

  const splitIntoVars = (param) => {

  };

  try {
    logger("Starting pitchPromoters process...");
    logger(`Received data: ${JSON.stringify({ scope_suffix, message, videoUrl, receivers })}`);

    let meetingAddress = "Unknown";
    let meetingDate = "";
    let meetingTime = "";
    let meetingPradhanName = "Pradhaan";
    let meetingPradhaanDP = 'https://icon-library.com/images/anonymous-avatar-icon/anonymous-avatar-icon-25.jpg';

    const meetingSnapshot = await admin.firestore().collection('meetings').doc(scope_suffix).get();
    if (meetingSnapshot.exists) {
      const meetingData = meetingSnapshot.data();

      meetingAddress = meetingData.address;

      // Format the meeting date as day/month/year
      meetingDate = meetingData.created_at.toDate().toLocaleDateString('en-IN', {
        day: '2-digit',   // Two-digit day (e.g., "05")
        month: '2-digit', // Two-digit month (e.g., "08")
        year: 'numeric'   // Full year (e.g., "2024")
      });

      // Format the meeting time as hour12:minutes am/pm
      meetingTime = meetingData.created_at.toDate().toLocaleTimeString('en-IN', {
        hour: 'numeric',   // Hour in 12-hour format
        minute: '2-digit', // Two-digit minute
        hour12: true       // Use 12-hour format with AM/PM
      });

    } else {
      logger("Meeting doesn't exists")
    }

    const pradhanSnapshot = await admin.firestore().collection('users').doc(context.auth?.uid).get();
    if (pradhanSnapshot.exists) {
      const pradhanData = pradhanSnapshot.data();
      if (pradhanData.name && pradhanData.dp) {
        meetingPradhanName = pradhanData.name;
        meetingPradhaanDP = pradhanData.image;
      }
    } else {
      logger("Pradhaan data doesn't exists")
    }

    const promoterEmails = {};
    const promoterPhones = {};

    // Loop through each UID to fetch the corresponding contact details
    for (const uid of receivers) {
      try {
        const docRef = admin.firestore().collection('contacts').doc(uid);
        const doc = await docRef.get();

        if (doc.exists) {
          const contactData = doc.data();
          if (contactData && contactData.email) {
            promoterEmails[contactData.email] = uid; // Push email if it exists
          } else if (contactData && contactData.phone) {
            promoterPhones[contactData.phone] = uid; // Push email if it exists
          } else {
            logger("no valid contact data found for " + uid)
          }
        } else {
          logger("contact data not found for " + uid)
        }
      } catch (error) {
        logger(`Error while getting contact details: ${error}`);
      }
    }

    logger(`emails: ${JSON.stringify(promoterEmails)}`)
    logger(`phones: ${JSON.stringify(promoterPhones)}`)

    let phoneResult;
    let mailResult;

    if (promoterPhones && Object.keys(promoterPhones).length > 0) {
      logger(`Sending messages`);

      const param1 = (message || 'join us for an important discussion.').replace('~', '-');

      const temp = `${meetingDate} at ${meetingTime}`
      const param2 = `${meetingAddress.substring(0, 60 - temp.length)} on ${temp}`;

      const var1 = param1.length > 30 ? param1.substring(0, 30) : param1.substring(0, param1.length - 1);
      const var2 = param1.length > 30 ? param1.substring(30) : param1.substring(param1.length - 1);

      const var3 = param2.length > 30 ? param2.substring(0, 30) : param2.substring(0, param2.length - 1);
      const var4 = param2.length > 30 ? param2.substring(30) : param2.substring(param2.length - 1);

      const body = {
        "sender": "PRDHHN",
        "templateName": "60 Character Explicit",
        "smsReciever": Object.keys(promoterPhones).map((key) => {
          const da = {
            "mobileNo": key.trim().length === 12 ? key.replace(/^91/, '') : key.replace(/^\+91/, ''),
            "templateParams": `${var1}~${var2}~${var3}~${var4}`
          };
          logger(`receiver: ${JSON.stringify(da)}`);
          return da;
        })
      };

      logger(`body: ${JSON.stringify(body)}`);

      const options = {
        headers: {
          'Content-Type': 'application/json',
          "Apikey": "BReIgCP43JmWYrx"
        }
      };

      try {
        phoneResult = await axios.post(
          "https://api.bulksmsadmin.com/BulkSMSapi/keyApiSendSMS/SendSmsTemplateName",
          body,
          options
        );

        logger(JSON.stringify(phoneResult.data));

        if (phoneResult.data.isSuccess || false) {
          phoneResult = Object.values(promoterPhones);
        }
      } catch (error) {
        phoneResult = error.message;
        logger(`error while sending sms: ${error}`);
      }
    }

    if (promoterEmails && Object.keys(promoterEmails).length > 0) {
      try {
        const mailOptions = {
          from: 'pradhaan@dbvertex.com',
          to: Object.keys(promoterEmails),
          subject: `Meeting Invitation ${meetingDetails.meetingDate}`,
          html: emailTemplate
            .replace('{{pradhaan.name}}', meetingPradhanName)
            .replace('{{meetingDate}}', meetingDate)
            .replace('{{meetingTime}}', meetingTime)
            .replace('{{meetingAddress}}', meetingAddress)
            .replace('{{customMessage}}', message || 'Please join us for an important discussion.'),
          attachments: [
            {
              filename: `pradhan_logo.jpg`,
              path: 'https://pradhaan.in/assets/images/new_logo_(2).png', // URL of the image
              cid: 'pradhan_logo' // This is the CID you will use in the HTML
            },
            {
              filename: `${scope_suffix}_pradhan_img.jpg`,
              path: meetingPradhaanDP || 'https://icon-library.com/images/anonymous-avatar-icon/anonymous-avatar-icon-25.jpg', // URL of the image
              cid: 'pradhan_dp' // This is the CID you will use in the HTML
            },
            {
              filename: `${scope_suffix}_video.mp4`,
              path: videoUrl, // URL of the image
              cid: 'video' // This is the CID you will use in the HTML
            }
          ]
        };

        await transporter.sendMail(mailOptions);

        mailResult = Object.values(promoterEmails);
      } catch (error) {
        mailResult = error.message;
        logger(`error while sending email: ${error}`);
      }
    }

    let data = [];
    if (phoneResult && Array.isArray(phoneResult)) {
      data = data.concat(phoneResult)
    }

    if (mailResult && Array.isArray(mailResult)) {
      data = data.concat(mailResult)
    }

    // Placeholder return for success
    const vall = data.length == 0;
    return { status_val: !vall, message: vall ? 'Pitch failed' : "Pitch successful.", logs: logger_logs, data };
  } catch (error) {
    logger(`Error occurred: ${error.message}`);
    return { status_val: false, message: error.message, logs: logger_logs };
  }
});


// exports.sendMail = functions.https.onCall(async (data, context) => {
//   const { scope_suffix, message, videoUrl, receivers } = data;

//   try {
//     const meetingDetails = {
//       meetingDate: 'Not Provided',
//       meetingTime: 'Not Provided',
//       meetingAddress: 'Not Provided',
//       pradhaan: {
//         name: 'Pradhaan',
//         dp: 'https://icon-library.com/images/anonymous-avatar-icon/anonymous-avatar-icon-25.jpg'
//       },
//     };

//     const pradhanSnapshot = await admin.firestore().collection('users').doc(context.auth?.uid).get();
//     if (pradhanSnapshot.exists) {
//       const pradhanData = pradhanSnapshot.data();

//       meetingDetails.pradhaan.name = pradhanData.name;
//       meetingDetails.pradhaan.dp = pradhanData.image;
//     }

//     const meetingSnapshot = await admin.firestore().collection('meetings').doc(scope_suffix).get();
//     if (meetingSnapshot.exists) {
//       const meetingData = meetingSnapshot.data();

//       meetingDetails.meetingAddress = meetingData.address;

//       // Format the meeting date and time
//       meetingDetails.meetingDate = meetingData.created_at.toDate().toLocaleDateString('en-IN', {
//         weekday: 'long',   // Full weekday name (e.g., "Monday")
//         year: 'numeric',   // Full year (e.g., "2024")
//         month: 'long',     // Full month name (e.g., "November")
//         day: 'numeric'     // Numeric day (e.g., "28")
//       });

//       meetingDetails.meetingTime = meetingData.created_at.toDate().toLocaleTimeString('en-IN', {
//         hour: 'numeric',   // Hour (24-hour format)
//         minute: 'numeric', // Minute
//         second: 'numeric', // Second (optional)
//         hour12: false      // Use 24-hour format
//       });
//     }

//     const emails = {};
//     const phones = {};
//     let logs = '';

// // Loop through each UID to fetch the corresponding contact details
// for (const uid of receivers) {
//   try {
//     const docRef = admin.firestore().collection('contacts').doc(uid);
//     const doc = await docRef.get();

//     if (doc.exists) {
//       const contactData = doc.data();
//       if (contactData && contactData.email) {
//         emails[contactData.email] = uid; // Push email if it exists
//       } else if (contactData && contactData.phone) {
//         phones[contactData.phone] = uid; // Push email if it exists
//       }
//     }
//   } catch (error) {
//     console.error('Error getting document:', error);
//     logs += `\n${error}`;
//   }
// }

// let mailResult;
// let phoneResult;

// if (emails && Object.keys(emails).length > 0) {
//   const mailOptions = {
//     from: 'pradhaan@dbvertex.com',
//     to: Object.keys(emails),
//     subject: `Meeting Invitation ${meetingDetails.meetingDate}`,
//     html: emailTemplate
//       .replace('{{pradhaan.name}}', meetingDetails.pradhaan.name || '')
//       .replace('{{meetingDate}}', meetingDetails.meetingDate || '')
//       .replace('{{meetingTime}}', meetingDetails.meetingTime || '')
//       .replace('{{meetingAddress}}', meetingDetails.meetingAddress || '')
//       .replace('{{customMessage}}', message || 'Please join us for an important discussion.'),
//     attachments: [
//       {
//         filename: `pradhan_logo.jpg`,
//         path: 'https://pradhaan.in/assets/images/new_logo_(2).png', // URL of the image
//         cid: 'pradhan_logo' // This is the CID you will use in the HTML
//       },
//       {
//         filename: `${scope_suffix}_pradhan_img.jpg`,
//         path: meetingDetails.pradhaan.dp || 'https://icon-library.com/images/anonymous-avatar-icon/anonymous-avatar-icon-25.jpg', // URL of the image
//         cid: 'pradhan_dp' // This is the CID you will use in the HTML
//       },
//       {
//         filename: `${scope_suffix}_video.mp4`,
//         path: videoUrl, // URL of the image
//         cid: 'video' // This is the CID you will use in the HTML
//       }
//     ]
//   };

//   mailResult = await transporter.sendMail(mailOptions);
// }

//     if (phones && Object.entries(phones).length > 0) {
//       const param2 = `${meetingDetails.meetingAddress} on ${meetingDetails.meetingDate} at ${meetingDetails.meetingTime}`;

//       const body = {
//         "sender": "PRDHHN",
//         "templateName": "Pradhaan pitch sms template",
//         "smsReciever": [{
//           "mobileNo": "9509718891", //Object.keys(phones).join(","),
//           "templateParams": "var~var"
//         }]
//       };

//       const options = {
//         headers: {
//           'Content-Type': 'application/json'
//         }
//       };

//       try {
//         phoneResult = await axios.post(
//           "https://api.bulksmsadmin.com/BulkSMSapi/keyApiSendSMS/sendSMS",
//           body,
//           options
//         );

//       } catch (error) {
//         phoneResult = error;
//         logs += `\n${error}`;
//       }

//     }
//     return {
//       status: emails && phones && (Object.keys(emails).length > 0 || Object.keys(phones).length > 0),
//       mail: {
//         receivers: emails,
//         result: mailResult
//       },
//       phone: {
//         receivers: phones,
//         result: phoneResult
//       }
//     };
//   } catch (error) {
//     return { message: error.message };
//   }
// });

const razorpayInstance = new Razorpay({
  key_id: "rzp_live_3HPV6HLj5SMWeS",
  key_secret: "gz3t0ogtZ2jDFRMz5mR6M43T",
  //key_id: "rzp_test_hZoY4pZlBherR0",
  //  key_secret: "xupCF9YGptU5qINoGJWZWQcv",
});

// DB Vertexy
// Create Order function

exports.addCustomer = functions.https.onCall(async (data, context) => {
  const { name, email, contact, accountNumber, ifsc, reference_id, notes } = data;

  // Validate inputs
  if (!name || !email || !contact || !accountNumber || !ifsc) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  try {
    // Ensure contact includes country code
    const formattedContact = `+91${contact}`; // Adjust based on your needs

    // Step 1: Create Razorpay contact
    const customerResponse = await axios.post(
      "https://api.razorpay.com/v1/contacts",
      {
        name,
        email,
        contact: formattedContact,
        type: "employee",
        reference_id,
        notes: notes || {},
      },
      {
        auth: {
          username: "rzp_test_yds44ayQjStCiB",
          password: "OQxUntrCV2bbk3fiB5CmmbGE",
        },
      },
      logs
    );

    const customerId = customerResponse.data.id;

    // Step 2: Link bank account
    const fundAccountResponse = await axios.post(
      "https://api.razorpay.com/v1/fund_accounts",
      {
        contact_id: customerId,
        account_type: "bank_account",
        bank_account: {
          name,
          ifsc,
          account_number: accountNumber,
        },
      },
      {
        auth: {
          username: "rzp_test_yds44ayQjStCiB",
          password: "OQxUntrCV2bbk3fiB5CmmbGE",
        },
      }
    );

    return { fundAccount: fundAccountResponse.data };
  } catch (error) {
    let errorMessage = "An unexpected error occurred.";

    // Check if the error is from the Axios response
    if (error.response) {
      // Extracting specific error details
      const status = error.response.status; // HTTP status code
      const message = error.response.data.error.message; // Error message from Razorpay API
      const errorCode = error.response.data.error.code; // Error code if available

      errorMessage = {
        status,
        message,
        errorCode,
      };
    } else if (error.request) {
      // The request was made but no response was received
      errorMessage = {
        status: "NO_RESPONSE",
        message: "No response received from the server.",
      };
    } else {
      // Something happened in setting up the request
      errorMessage = {
        message: error.message,
      };
    }

    // Logging the complete error for debugging
    console.error("Error details:", errorMessage);

    // Return a structured error response
    throw new functions.https.HttpsError("internal", JSON.stringify(errorMessage));
  }
});

exports.transferAmount = functions.https.onCall(async (data, context) => {
  const { account_number, fund_account_id, amount, currency, mode, purpose, queue_if_low_balance, reference_id, narration, notes } = data;

  try {
    const transferResponse = await axios.post(
      "https://api.razorpay.com/v1/payouts",
      {
        account_number: account_number,    // Account number (as per your requirement)
        fund_account_id: fund_account_id,   // Fund account ID
        amount: amount,                     // Amount in paise
        currency: currency,                 // Currency
        mode: mode,                         // Transfer mode (IMPS/NEFT/UPI)
        purpose: purpose,                   // Purpose of the payout
        queue_if_low_balance: queue_if_low_balance, // Queue if low balance
        reference_id: reference_id,         // Reference ID for the transaction
        narration: narration,               // Narration for the transaction
        notes: notes                        // Additional notes
      },
      {
        auth: {
          username: "rzp_test_yds44ayQjStCiB",
          password: "OQxUntrCV2bbk3fiB5CmmbGE",
        },
      }
    );

    return { transfer: transferResponse.data };
  } catch (error) {
    console.error("Error details:", error);
    if (error.response) {
      console.error("Razorpay error response:", error.response.data);
      throw new functions.https.HttpsError("internal", error.response.data.error.message);
    } else if (error.request) {
      throw new functions.https.HttpsError("internal", "No response received from Razorpay server.");
    } else {
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
});

exports.getWeekWiseBreakdown = functions.https.onCall(async (data, context) => {
  const userid = context.auth?.uid;

  if (!userid) {
    throw new functions.https.HttpsError('unauthenticated', 'You are not logged in.');
  }

  const { pradhan_id } = data;

  if (!pradhan_id) {
    throw new functions.https.HttpsError('invalid-argument', 'pradhan_id is required.');
  }

  try {
    // Fetch all view records where pradhan_id matches
    // const viewsSnapshot = await admin
    //   .firestore()
    //   .collection('views')
    //   .where('pradhan_id', '==', pradhan_id)
    //   .get();
//change by yash
  //  Fetch all view records where pradhan_id matches
    const viewsSnapshot = await admin
      .firestore()
      .collectionGroup('viewers')
      .where('pradhan_id', '==', pradhan_id).orderBy("created_at",'asc')
      .get();
    const adsByDateWithViews = {};

    // Fetch all necessary data concurrently
    const viewDataPromises = viewsSnapshot.docs.map(async (doc) => {
      const { ad_id, created_at } = doc.data();
      const weekDate = getWeekStartDateInIST(new Date(created_at.toDate())).toISOString();

      if (!adsByDateWithViews[weekDate]) {
        adsByDateWithViews[weekDate] = {};
      }
      if (!adsByDateWithViews[weekDate][ad_id]) {
        // Fetch ad details
        const adDoc = await admin.firestore().collection('ads').doc(ad_id).get();
        if (!adDoc.exists) return;

        const { uid, target_views, proposed_amount } = adDoc.data();

        // Fetch user details for the ad creator
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        if (!userDoc.exists) return;

        const { name, image, level } = userDoc.data();

        // Calculate per-view amount
        const amountPerView = (proposed_amount || 0) / (target_views || 1);

        adsByDateWithViews[weekDate][ad_id] = {
          views: 0,
          amountPerView,
          name,
          image,
          level,
        };
      }

      // Increment the view count for the ad in this week
      adsByDateWithViews[weekDate][ad_id].views += 1;
    });

    // Wait for all data fetching to complete
    await Promise.all(viewDataPromises);

    // Calculate total amounts for each ad
    for (const weekDate in adsByDateWithViews) {
      for (const adId in adsByDateWithViews[weekDate]) {
        const adData = adsByDateWithViews[weekDate][adId];
        adData.total_amount = adData.amountPerView * adData.views; // Multiply amountPerView and views
      }
    }

    return adsByDateWithViews; // Return the results
  } catch (error) {
    console.error('Error fetching data:', error);
    throw new functions.https.HttpsError('internal', `An unexpected error occurred. (${error})`);
  }
});

function getWeekStartDateInIST(date) {
  if (!(date instanceof Date)) {
    throw new Error("Input must be a Date object");
  }

  // Clone the input date to avoid mutating it
  const inputDate = new Date(date);

  // Convert the input date to Indian Standard Time (IST), which is UTC +5:30
  const offsetIST = 5.5 * 60 * 60 * 1000; // 5.5 hours in milliseconds
  const localTimeInIST = new Date(inputDate.getTime() + offsetIST);

  // Get the day of the week (0 = Sunday, 6 = Saturday)
  const dayOfWeek = localTimeInIST.getDay();

  // Calculate the difference to the nearest Sunday (start of the week)
  const diffToSunday = dayOfWeek;

  // Set the date to the start of the week (Sunday)
  localTimeInIST.setDate(localTimeInIST.getDate() - diffToSunday);

  // Reset time to midnight in IST
  localTimeInIST.setHours(0, 0, 0, 0);

  // Adjust back to UTC for Firebase compatibility (optional)
  const finalDate = new Date(localTimeInIST.getTime() - offsetIST);

  return finalDate;
}

exports.getAdvertisers = functions.https.onCall(async (data, context) => {
  const scopeSuffix = data.scope_suffix;

  try {
    const adSnapshots = await admin.firestore()
      .collection('ads')
      .where('scope_suffix', '==', scopeSuffix)
      .get();

    if (adSnapshots.empty) {
      return { error: 'No ads found for this scope.' };
    }

    const advertisersMap = new Map(); // To track users and their ad amounts

    // Process each ad
    for (const adDoc of adSnapshots.docs) {
      const adData = adDoc.data();
      const uid = adData?.uid;

      if (!uid) continue;

      // Get or initialize advertiser's data in the map
      if (!advertisersMap.has(uid)) {
        advertisersMap.set(uid, {
          uid,
          total_amount: 0,
          current_week_amount: 0,
        });
      }

      const advertiser = advertisersMap.get(uid);

      // Accumulate ad amounts
      const proposedAmount = adData?.proposed_amount || 0;
      advertiser.total_amount += proposedAmount;

      const createdAt = adData?.created_at?.toDate?.() || adData?.created_at;
      if (createdAt && isCurrentWeek(new Date(createdAt))) {
        advertiser.current_week_amount += proposedAmount;
      }
    }

    // Fetch user details for the collected UIDs
    const advertisers = await Promise.all(
      Array.from(advertisersMap.values()).map(async (advertiser) => {
        const userSnapshot = await admin.firestore()
          .collection('users')
          .doc(advertiser.uid)
          .get();

        const userData = userSnapshot.data();
        if (userData) {
          return {
            uid: advertiser.uid,
            name: userData.name || null,
            username: userData.username || null,
            image: userData.image || null,
            level: userData.level || null,
            total_amount: advertiser.total_amount,
            current_week_amount: advertiser.current_week_amount,
            type: 'Advertiser'
          };
        }
        return null;
      })
    );

    const externalContributorsSnapshots = await admin.firestore().collection("external_promoters").where('scope', '==', scopeSuffix).get();
    for (const promoter of externalContributorsSnapshots.docs) {
      const promoterData = promoter.data();
      if (promoterData) {
        advertisers.push({
          uid: promoter.id,
          name: promoterData.name || null,
          username: promoterData.username || null,
          image: promoterData.image || null,
          level: 1,
          total_amount: promoterData.total_contribution,
          current_week_amount: promoterData.weekly_contribution,
          type: 'Sponsor'
        });
      }
    }

    // Filter out users with no data
    const filteredAdvertisers = advertisers.filter((advertiser) => advertiser !== null);

    // Sort advertisers by total_amount in descending order
    filteredAdvertisers.sort((a, b) => b.total_amount - a.total_amount);

    return {
      advertisers: filteredAdvertisers,
    };
  } catch (error) {
    throw new functions.https.HttpsError('unknown', error.message);
  }
});

// Helper function to check if a date is in the current week
function isCurrentWeek(date) {
  const now = new Date();
  const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay() + 1)); // Start of the week (Monday)
  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6); // End of the week (Sunday)

  startOfWeek.setHours(0, 0, 0, 0);
  endOfWeek.setHours(23, 59, 59, 999);

  return date >= startOfWeek && date <= endOfWeek;
}

exports.createOrder = functions.https.onCall(async (data, context) => {
  // Validate that amount is provided
  if (!data.amount) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with an amount.');
  }

  console.log(context);

  const amount = data.amount * 100;

  const options = {
    amount: amount,
    currency: "INR",
    receipt: `receipt_order_${new Date().getTime()}`,
    notes: {
      note: data.note
    }
  };

  try {
    const order = await razorpayInstance.orders.create(options);
    return { orderId: order.id }; // Return the order ID
  } catch (error) {
    throw new functions.https.HttpsError('unknown', error.message); // Throw an error with a message
  }
});

exports.getDonationDetailsForScope = functions.https.onCall(async (data, context) => {
  const scopeSuffix = data.scope_suffix;
  const returnDonors = data.return_donors || false;

  // Check authentication
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'You are not authorized to access pradhaan details');
  }

  console.log(context);

  // Validate input
  if (!scopeSuffix) {
    throw new functions.https.HttpsError('invalid-argument', 'scopeSuffix is required.');
  }

  let totalFundInCampaign = 0;
  let donorsList = [];
  let totalAmountSpent = 0;
  let totalRideProvided = 0;
  let firstEntryDate = null;

  try {
    // Fetch donations for the given scope
    const donationsSnapshot = await admin.firestore()
      .collection('donations')
      .where('location', '==', scopeSuffix)
      .get();

    if (donationsSnapshot.empty) {
      return { error: 'No donations found for this scope.' };
    }

    // Create an array of promises to process donations
    const donationPromises = donationsSnapshot.docs.map(async (doc) => {
      const donation = doc.data();
      const amount = donation.amount || 0;

      totalFundInCampaign += amount;

      // If return_donors is true, collect donor details
      if (returnDonors) {
        const userSnapshot = await admin.firestore().collection('users').doc(donation.by).get();
        donorsList.push({
          id: donation.by,
          name: userSnapshot?.data()?.name || 'Unknown contributor',
          profilePhoto: userSnapshot?.data()?.image || null,
          totalDonated: amount,
          datetime: donation.datetime
        });
      }
    });

    // Wait for all donation promises to resolve
    await Promise.all(donationPromises);

    // Fetch daily rides data
    const rideSnapshot = await admin.firestore().collection('dailyrides').where('location', '==', scopeSuffix).get();

    if (!rideSnapshot.empty) {
      // Process rides and calculate total amount, total distance, and get the first entry date
      rideSnapshot.docs.forEach(doc => {
        const rideData = doc.data();
        totalAmountSpent += rideData.amount || 0;
        totalRideProvided += rideData.distance || 0;

        // Set the first entry date based on the earliest datetime field
        if (!firstEntryDate || rideData.datetime.toDate() < firstEntryDate) {
          firstEntryDate = rideData.datetime;  // Keeping it as Firestore Timestamp
        }
      });
    }

    // Return the final response with calculated values
    return {
      totalFundInCampaign,
      usedFundFromCampaign: totalAmountSpent,
      totalRideProvided,
      firstEntryDate,  // Returning as Firestore Timestamp
      donors: returnDonors ? donorsList : null
    };

  } catch (error) {
    console.error('Error fetching details:', error);
    throw new functions.https.HttpsError('internal', `Internal Server Error: ${error.message}`);
  }
});

exports.storeViewAndUpdateGeneratedViews = functions.https.onCall(async (data, context) => {
  const adId = data.ad_id; // Get ad_id from the data object
  const viewerId = context.auth?.uid; // Get viewer_id from the auth context
  //  const scopeSuffix = data.scope_suffix;

  // Validate ad_id and viewer_id
  if (!adId || !viewerId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `ad_id (${adId}) and viewer_id (${viewerId}) are required.`
    );
  }

  const adRef = admin.firestore().collection('ads').doc(adId);
  const viewRef = admin.firestore().collection('views').doc(adId).collection('viewers').doc(viewerId);
  const batch = admin.firestore().batch();

  try {
    const adDoc = await adRef.get();

    // Check if the ad document exists
    if (!adDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        `Ad with id (${adId}) not found`
      );
    }

    const adData = adDoc.data();
    const generatedViews = adData.generated_views || 0;
    const targetViews = adData.target_views || 0;

    // Check if generated views exceed target views
    if (generatedViews + 1 > targetViews) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Request failed: ad (${adId}) is already completed`
      );
    }
    // Check if the viewer_id already exists in views/ad_id/viewers/viewer_id
    const viewDoc = await viewRef.get();
//change on 1/07/25 due to increase view conunt for same user:
    // if (viewDoc.exists) {
    //   throw new functions.https.HttpsError(
    //     'already-exists',
    //     `Viewer (${viewerId}) has already viewed this ad (${adId}).`
    //   );
    // }

    // Get scope_suffix from the ad document
    const scopeSuffix = adData.scope_suffix;
    if (!scopeSuffix) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `scope_suffix is missing in ad (${adId}).`
      );
    }


    //    // Check if the viewer already has a view recorded for this ad
    //    const existingViewQuery = await admin.firestore()
    //      .collection('views')
    //      .where('ad_id', '==', adId)
    //      .where('viewer_id', '==', viewerId)
    //      .get();
    //
    //    if (!existingViewQuery.empty) {
    //      throw new functions.https.HttpsError(
    //        'already-exists',
    //        `Viewer (${viewerId}) has already viewed this ad (${adId}).`
    //      );
    //    }

    // Get scope_suffix from the ad document
    // const scopeSuffix = adData.scope_suffix; // Assuming scope_suffix is stored in the `ads` document

    // Get pradhan_id from pradhan/scope_suffix document
    const pradhanRef = admin.firestore().collection('pradhan').doc(scopeSuffix);
    const pradhanDoc = await pradhanRef.get();

    let pradhanId = 'admin'; // Default to 'admin' if pradhan document doesn't exist

    if (pradhanDoc.exists) {
      const pradhanData = pradhanDoc.data();
      pradhanId = pradhanData.pradhan_id || 'admin'; // Use pradhan_id from document or 'admin'
    }

    //    // Create a new random document in the `views` collection
    //    const newViewRef = admin.firestore().collection('views').doc();
    //
    //    const newViewData = {
    //      ad_id: adId,
    //      viewer_id: viewerId,
    //      created_at: admin.firestore.FieldValue.serverTimestamp(),
    //      scope: scopeSuffix,
    //      pradhan_id: pradhanId,
    //    };
    //
    //    batch.set(newViewRef, newViewData);
    // Save view data in views/ad_id/viewers/viewer_id
    const viewData = {
      pradhan_id: pradhanId,
      scope: scopeSuffix,
      ad_id: adId,
      viewer_id: viewerId,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    batch.set(viewRef, viewData);

    // Update the `generated_views` field in the `ads` document
    batch.update(adRef, { generated_views: generatedViews + 1 });

    await batch.commit();

    return {
      message: "View stored and generated views updated successfully",
      adId,
      viewerId,
      pradhanId,
      scope: scopeSuffix,
    };
  } catch (error) {
    console.error('Error in storeViewAndUpdateGeneratedViews:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Internal Server Error: ${error.message}`
    );
  }
});

exports.getRevenueDetailsForScope = functions.https.onCall(async (data, context) => { // Migrated
  try {
    const scope = data.scope;
    const scopeSuffix = data.scope_suffix;

    if (!scopeSuffix) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `scope_suffix (${scopeSuffix}) is required.`
      );
    }

    const pradhanSnapshot = await admin.firestore().collection('pradhan').doc(scopeSuffix).get();
    const _pradhanData = pradhanSnapshot.data()?.pradhan_model;
    let pradhaanRevenue = 0;
    let pradhaanRemainingBalance = 0;

    try {
      const walletData = await admin.firestore().collection('wallets').doc(_pradhanData?.id).get();
      pradhaanRevenue = walletData?.data()?.amount || 0;
      pradhaanRemainingBalance = walletData?.data()?.used_amount || 0;
    } catch (error) {
      // throw new functions.https.HttpsError(
      //   'internal',
      //   `Internal Server Error: ${error.message}`
      // );
    }

    const pradhanData = {
      pradhanId: _pradhanData?.id || 'none',
      pradhanName: _pradhanData?.name || 'Unknown',
      pradhanProfileImage: _pradhanData?.image || 'none',
      pradhanDesc: _pradhanData?.userdesc || '',
      pradhaanRevenue,
      pradhaanRemainingBalance,
    };


    let totalAdsCreated = 0;
    let revenueOnOffer = 0.0;
    let totalViewsGenerated = 0;
    let totalRevenueTransferred = 0;

    const adsSnapshot = await admin.firestore()
      .collection('ads')
      .where('scope_suffix', '==', scopeSuffix)
      .get();

    if (!adsSnapshot.empty) {
      for (const adDoc of adsSnapshot.docs) {
        const adData = adDoc.data();
        totalAdsCreated++;
        revenueOnOffer += adData.proposed_amount || 0;
        totalViewsGenerated += adData.generated_views || 0;

        const targetViews = adData.target_views || 1; // Prevent division by zero
        const amountPerView = (adData.proposed_amount || 0) / targetViews;

        // Calculate revenue transferred based on generated views
        totalRevenueTransferred += amountPerView * (adData.generated_views || 0);

        if (pradhanData.pradhanId !== 'none') {
          // Fetch views specific to the current Pradhaan for this ad
          // const viewsSnapshot = await admin.firestore()
          //   .collection('views')
          //   .where('ad_id', '==', adDoc.id)
          //   .where('pradhan_id', '==', pradhanData.pradhanId)
          //   .get();
          const viewsSnapshot = await admin.firestore()
            .collectionGroup('viewers')
            .where('ad_id', '==', adDoc.id)
            .where('pradhan_id', '==', pradhanData.pradhanId).orderBy('created_at','asc')
            .get();

          // Calculate Pradhaan's revenue based on the views they generated
          pradhaanRevenue += amountPerView * viewsSnapshot.size;
        }
      }
    }

    return {
      totalAdsCreated,
      revenueOnOffer,
      totalViewsGenerated,
      totalRevenueTransferred,
      pradhanData
    };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      `Internal Server Error: ${error.message}`
    );
  }
});

exports.getRevenueDetailsForPradhaan = functions.https.onCall(async (data, context) => { // Migrated
  const pradhaanID = data.pradhaan_id;

  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You are not authorized to access pradhaan details.'
    );
  }

  if (!pradhaanID) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'pradhaan_id is required.'
    );
  }

  let totalViewsGeneratedByPradhaan = 0;
  let pradhaanRevenue = 0;
  let pradhaanRemainingBalance = 0;

  try {
    // const viewsSnapshot = await admin.firestore()
    //   .collection('views')
    //   .where('pradhan_id', '==', pradhaanID)
    //   .get();

    const viewsSnapshot = await admin.firestore()
      .collectionGroup('viewers')
      .where('pradhan_id', '==', pradhaanID).orderBy('created_at','asc')
      .get();
    totalViewsGeneratedByPradhaan = viewsSnapshot.docs.length || 0;
  } catch (error) {
    console.log('errot on fatching views on getRevenueDetaillsForPradhan.:', error);
   }

  try {
    const walletData = await admin.firestore().collection('wallets').doc(pradhaanID).get();
    pradhaanRevenue = walletData?.data()?.amount || 0;
    pradhaanRemainingBalance = walletData?.data()?.used_amount || 0;
  } catch (error) { 
    console.log('error on wallet data updation . : ',error);
  }

  //  try {
  //    const viewsSnapshot = await admin.firestore()
  //      .collection('views')
  //      .where('pradhan_id', '==', pradhaanID)
  //      .get();
  //
  //    totalViewsGeneratedByPradhaan = viewsSnapshot.docs.length || 0;
  //  } catch (error) {
  //    throw new functions.https.HttpsError(
  //      'internal',
  //      `Internal Server Error: ${error.message}`
  //    );
  //  }
  //
  //  try {
  //    const walletData = await admin.firestore().collection('wallets').doc(pradhaanID).get();
  //    pradhaanRevenue = walletData?.data()?.amount || 0;
  //    pradhaanRemainingBalance = walletData?.data()?.used_amount || 0;
  //  } catch (error) {
  //    throw new functions.https.HttpsError(
  //      'internal',
  //      `Internal Server Error: ${error.message}`
  //    );
  //  }



  return {
    totalViewsGeneratedByPradhaan,
    pradhaanRevenue,
    pradhaanRemainingBalance,
  };
});

function shuffle(array) {
  let currentIndex = array.length;

  // While there remain elements to shuffle...
  while (currentIndex != 0) {

    // Pick a remaining element...
    let randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    // And swap it with the current element.
    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex], array[currentIndex]];
  }

  return array;
}

exports.capturePayment = functions.https.onCall(async (data, context) => {
  const { payment_id, amount } = data;
  try {

    const response = await razorpayInstance.payments.capture(payment_id, amount, 'INR');
    return { rzr_res: response, captured: response?.captured };
  } catch (error) {
    return { message: error };
  }
});

//change by yg,. 2/7/25
// exports.getRandomAd = functions.https.onCall(async (data, context) => {
//   const scope = data.scope || []; // Get the scope from the data object
//   const uid = context.auth?.uid; // Get the logged-in user's UID

//   if (!uid) {
//     throw new functions.https.HttpsError("unauthenticated", "The user must be authenticated.");
//   }

//   // Function to generate a random value
//   const getRandomDouble = () => Math.random();

//   try {
//     const randomValue = getRandomDouble();

//     const viewsAdIds = [];
//     // const viewsSnapshot = await admin.firestore().collection('views').where('viewer_id', '!=', uid).get();
// const viewsSnapshot = await admin.firestore().collectionGroup('viewers').where('viewer_id', '!=', uid).orderBy('created_at','asc').get();
//     if (viewsSnapshot.docs) {
//       for (const doc of viewsSnapshot.docs) {
//         const data = doc.data();
//         if (data && data.ad_id) {
//           viewsAdIds.push(data.ad_id);
//         }
//       }
//     }

//     const query = admin.firestore()
//       .collection("ads")
//       .where("scope", "array-contains-any", scope)
//       .where('uid', '!=', uid)
//       .where("randomness", ">=", randomValue);

//     const result = await query.get();

//     let documents = result.docs;

//     documents = documents.map(ad => ad.data());

//     // Filter the ads based on target_views and generated_views
//     let ads = documents.filter(ad => ad.uid != uid && (ad.target_views || 0) > (ad.generated_views || 0) && !viewsAdIds.includes(ad.id));

//     if (ads.length === 0) {
//       return { message: `No suitable ads found for scope: ${scope}`, viewed: viewsAdIds };
//     }

//     // Sort ads based on priority and ratio of generated_views to target_views
//     ads.sort((a, b) => {
//       // Compare by priority first
//       const priorityComparison = b.priority - a.priority;

//       if (priorityComparison !== 0) {
//         return priorityComparison;
//       }

//       // Calculate view ratios
//       const aRatio = (a.generated_views || 0) / (a.target_views || 1);
//       const bRatio = (b.generated_views || 0) / (b.target_views || 1);

//       return bRatio - aRatio; // Sort by ratio in descending order
//     });

//     // Return the top  5 ad after sorting
//     let selectedAd = shuffle(ads);

//     if (selectedAd.length > 8) {
//       selectedAd = selectedAd.slice(0, 8);
//     }

//     return selectedAd;
//   } catch (error) {
//     throw new functions.https.HttpsError("internal", `Error fetching ad: ${error.message || error}`);
//   }
// });



// exports.getRandomAd = functions.https.onCall(async (data, context) => {
//   const scope = data.scope || []; // Get the scope from the data object
//   const uid = context.auth?.uid; // Get the logged-in user's UID

//   if (!uid) {
//     throw new functions.https.HttpsError("unauthenticated", "The user must be authenticated.");
//   }

//   // Function to generate a random value
//   const getRandomDouble = () => Math.random();
// console.log("generated getRandomDouble:", getRandomDouble);

//   try {
//     const randomValue = getRandomDouble();
//     console.log("generated randomValue:", getRandomDouble);



//     const viewsAdIds = [];
//     // const viewsSnapshot = await admin.firestore().collection('views').where('viewer_id', '!=', uid).get();
// const viewsSnapshot = await admin.firestore().collectionGroup('viewers').where('viewer_id', '!=', uid).orderBy('created_at','asc').get();
//     if (viewsSnapshot.docs) {
//       for (const doc of viewsSnapshot.docs) {
//         const data = doc.data();
//         if (data && data.ad_id) {
//           viewsAdIds.push(data.ad_id);
//         }
//       }
//     }

//     const query = admin.firestore()
//       .collection("ads")
//       .where("scope", "array-contains-any", scope)
//       .where('uid', '!=', uid)
//       .where("randomness", ">=", randomValue);

//     const result = await query.get();

//     let documents = result.docs;

//     documents = documents.map(ad => ad.data());


//     //add new : 3*7*25
//    if (documents.length === 0) {
//       const fallbackQuery = admin.firestore()
//         .collection("ads")
//         .where("scope", "array-contains-any", scope)
//         .where('uid', '!=', uid)
//         .where("randomness", "<", randomValue);

//       const fallbackResult = await fallbackQuery.get();
//       documents = fallbackResult.docs.map(ad => ad.data());
//     }


//     // Filter the ads based on target_views and generated_views
//     let ads = documents.filter(ad => ad.uid != uid && (ad.target_views || 0) > (ad.generated_views || 0) && !viewsAdIds.includes(ad.id));

//     if (ads.length === 0) {
//       return { message: `No..... suitable ads found for scope: ${scope}`, viewed: viewsAdIds };
//     }

//     // Sort ads based on priority and ratio of generated_views to target_views
//     ads.sort((a, b) => {
//       // Compare by priority first
//       const priorityComparison = b.priority - a.priority;

//       if (priorityComparison !== 0) {
//         return priorityComparison;
//       }

//       // Calculate view ratios
//       const aRatio = (a.generated_views || 0) / (a.target_views || 1);
//       const bRatio = (b.generated_views || 0) / (b.target_views || 1);

//     //  return bRatio - aRatio; // Sort by ratio in descending order
//     return aRatio - bRatio;
//     });

//     // Return the top  5 ad after sorting
//     let selectedAd = shuffle(ads);

//     if (selectedAd.length > 8) {
//       selectedAd = selectedAd.slice(0, 8);
//     }

//     return selectedAd;
//   } catch (error) {
//     throw new functions.https.HttpsError("internal", `Error fetching ad: ${error.message || error}`);
//   }
// });

// exports.getRandomAd = functions.https.onCall(async (data, context) => {
//   const scope = data.scope || [];
//   const uid = context.auth?.uid;

//   if (!uid) {
//     throw new functions.https.HttpsError("unauthenticated", "The user must be authenticated.");
//   }

//   const getRandomDouble = () => Math.random();
//   const randomValue = getRandomDouble();

//   console.log("[INFO] Scope received:", scope);
//   console.log("[INFO] Current User UID:", uid);
//   console.log("[INFO] Generated randomValue:", randomValue);

//   try {
//     const viewsAdIds = [];
    
//     const viewsSnapshot = await admin.firestore()
//       .collectionGroup('viewers')
//       .where('viewer_id', '==', uid) // ✅ match only current user's viewed ads
//       .orderBy('created_at', 'asc')
//       .get();

//     if (viewsSnapshot.docs.length > 0) {
//       for (const doc of viewsSnapshot.docs) {
//         const data = doc.data();
//         if (data && data.ad_id) {
//           viewsAdIds.push(data.ad_id);
//         }
//       }
//     }

//     console.log("[INFO] Viewed Ad IDs:", viewsAdIds);

//     // Initial Query
//     const query = admin.firestore()
//       .collection("ads")
//       .where("scope", "array-contains-any", scope)
//       .where("uid", "!=", uid)
//       .where("randomness", ">=", randomValue);

//     let result = await query.get();
//     let documents = result.docs.map(doc => doc.data());

//     console.log("[INFO] Ads from >= randomness query:", documents.map(ad => ad.id));

//     // Fallback query if no ads found
//     if (documents.length === 0) {
//       console.log("[INFO] No ads in >= query, trying fallback < randomness...");

//       const fallbackQuery = admin.firestore()
//         .collection("ads")
//         .where("scope", "array-contains-any", scope)
//         .where("uid", "!=", uid)
//         .where("randomness", "<", randomValue);

//       const fallbackResult = await fallbackQuery.get();
//       documents = fallbackResult.docs.map(doc => doc.data());

//       console.log("[INFO] Ads from < randomness query:", documents.map(ad => ad.id));
//     }

//     // Filtering
//     let ads = documents.filter(ad => {
//       const isValid = ad.uid != uid &&
//         (ad.target_views || 0) > (ad.generated_views || 0) &&
//         !viewsAdIds.includes(ad.id);

//       console.log("[FILTER] Checking ad:", ad.id, {
//         title: ad.title,
//         valid: isValid,
//         viewed: viewsAdIds.includes(ad.id),
//         gen: ad.generated_views,
//         target: ad.target_views,
//         uidMatch: ad.uid == uid
//       });

//       return isValid;
//     });

//     if (ads.length === 0) {
//       console.log("[INFO] No suitable ads after filtering.");
//       return { message: `No..... suitable ads found for scope: ${scope}`, viewed: viewsAdIds };
//     }

//     // Sorting
//     ads.sort((a, b) => {
//       const priorityDiff = b.priority - a.priority;
//       if (priorityDiff !== 0) return priorityDiff;

//       const aRatio = (a.generated_views || 0) / (a.target_views || 1);
//       const bRatio = (b.generated_views || 0) / (b.target_views || 1);
//       return aRatio - bRatio; // lower ratio first
//     });

//     console.log("[INFO] Sorted Ads (after filtering):", ads.map(ad => ad.id));

//     // Shuffle & limit
//     const shuffle = (array) => {
//       for (let i = array.length - 1; i > 0; i--) {
//         const j = Math.floor(Math.random() * (i + 1));
//         [array[i], array[j]] = [array[j], array[i]];
//       }
//       return array;
//     };

//     let selectedAd = shuffle(ads);
//     if (selectedAd.length > 8) {
//       selectedAd = selectedAd.slice(0, 8);
//     }

//     console.log("[SUCCESS] Returning Ads:", selectedAd.map(ad => ad.id));
//     return selectedAd;

//   } catch (error) {
//     console.error("[ERROR] Fetching ad failed:", error);
//     throw new functions.https.HttpsError("internal", `Error fetching ad: ${error.message || error}`);
//   }
// });



exports.getRandomAd = functions.https.onCall(async (data, context) => {
const scope = data.scope || [];
  const uid = context.auth?.uid;

  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "The user must be authenticated.");
  }

  const getRandomDouble = () => Math.random();
  const randomValue = getRandomDouble();

  console.log("[INFO] Scope received:", scope);
  console.log("[INFO] Current User UID:", uid);
  console.log("[INFO] Generated randomValue:", randomValue);

  try {
    const viewsAdIds = [];
    
    const viewsSnapshot = await admin.firestore()
      .collectionGroup('viewers')
      .where('viewer_id', '==', uid) // ✅ match only current user's viewed ads
      .orderBy('created_at', 'asc')
      .get();

    if (viewsSnapshot.docs.length > 0) {
      for (const doc of viewsSnapshot.docs) {
        const data = doc.data();
        if (data && data.ad_id) {
          viewsAdIds.push(data.ad_id);
        }
      }
    }

    console.log("[INFO] Viewed Ad IDs:", viewsAdIds);
    const preCheck = await admin.firestore()
            .collection("ads")
            .where("scope", "array-contains-any", scope)
            .where("uid", "!=", uid)
            .get();
          console.log("[DEBUG] Total ads before randomness:", preCheck.docs.map(d => d.id));
    // Initial Query
    const query = admin.firestore()
      .collection("ads")
      .where("scope", "array-contains-any", scope)
      .where("uid", "!=", uid);
      //.where("randomness", ">=", randomValue);

    let result = await query.get();
    let documents = result.docs.map(doc => doc.data());

    console.log("[INFO] Ads from >= randomness query:", documents.map(ad => ad.id));

    // Fallback query if no ads found
    if (documents.length === 0) {
      console.log("[INFO] No ads in >= query, trying fallback < randomness...");

      const fallbackQuery = admin.firestore()
        .collection("ads")
        .where("scope", "array-contains-any", scope)
        .where("uid", "!=", uid);
        //.where("randomness", "<", randomValue);

      const fallbackResult = await fallbackQuery.get();
      documents = fallbackResult.docs.map(doc => doc.data());

      console.log("[INFO] Ads from < randomness query:", documents.map(ad => ad.id));
    }

    // Filtering
    let ads = documents.filter(ad => {
      const isValid = ad.uid != uid &&
        (ad.target_views || 0) > (ad.generated_views || 0) &&
        !viewsAdIds.includes(ad.id);
      /*ad.uid != uid &&
        (ad.target_views || 0) > (ad.generated_views || 0) &&
        !viewsAdIds.includes(ad.id);*/

      console.log("[FILTER] Checking ad:", ad.id, {
        title: ad.title,
        valid: isValid,
        viewed: viewsAdIds.includes(ad.id),
        gen: ad.generated_views,
        target: ad.target_views,
        uidMatch: ad.uid == uid
      });

      return isValid;
    });

    if (ads.length === 0) {
      console.log("[INFO] No suitable ads after filtering.");
      return { message: `No..... suitable ads found for scope: ${scope}`, viewed: viewsAdIds };
    }

    // Sorting
    ads.sort((a, b) => {
      const priorityDiff = b.priority - a.priority;
      if (priorityDiff !== 0) return priorityDiff;

      const aRatio = (a.generated_views || 0) / (a.target_views || 1);
      const bRatio = (b.generated_views || 0) / (b.target_views || 1);
      return aRatio - bRatio; // lower ratio first
    });

    console.log("[INFO] Sorted Ads (after filtering):", ads.map(ad => ad.id));

    // Shuffle & limit
    const shuffle = (array) => {
      for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
      }
      return array;
    };

    let selectedAd = shuffle(ads);
    if (selectedAd.length > 8) {
      selectedAd = selectedAd.slice(0, 8);
    }

    console.log("[SUCCESS] Returning Ads:", selectedAd.map(ad => ad.id));
    return selectedAd;

  } catch (error) {
    console.error("[ERROR] Fetching ad failed:", error);
    throw new functions.https.HttpsError("internal", `Error fetching ad: ${error.message || error}`);
  }
});


exports.updateVoteableCounts = functions.https.onRequest(async (req, res) => {
  try {
    const collectionRef = admin.firestore().collection('users');

    const snapshot = await collectionRef.get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      const newVotingValue = 0;
      batch.update(doc.ref, { todays_upvote: newVotingValue, oneday_vote: newVotingValue });
    });

    await batch.commit();

    res.status(200).send('Todays Vote Count  updated.');
  } catch (error) {
    console.error('Error updating Todays Vote Count:', error);
    res.status(500).send('An error occurred while updating Todays Vote Count.');
  }

});

exports.updateAreaSachive = functions.https.onRequest(async (req, res) => {
  try {
    const sachivCollection = admin.firestore().collection('sachiv');
    const userCollection = admin.firestore().collection('users');

    const sachivSnapshot = await sachivCollection.get();
    const batch = admin.firestore().batch();

    // Loop through each Sachiv document
    for (const sachiveDoc of sachivSnapshot.docs) {
      const sachivData = sachiveDoc.data();
      const sachivAreaLevel = sachivData.level;
      const sachivAreaText = sachivData.locationText;
      console.log("sachivAreaLevel: " + sachivAreaLevel + ", sachivAreaText: " + sachivAreaText);

      var locQuery = "postal.text";
      switch (sachivAreaLevel) {
        case 1:
          locQuery = "postal.text";
          break;
        case 2:
          locQuery = "city.text";
          break;
        case 3:
          locQuery = "state.text";
          break;
        case 4:
          locQuery = "country.text";
          break;
        default:
          locQuery = "postal.text";
          break;
      }

      console.log("locQuery: " + locQuery);

      // Query for posts with highest votes and full_add containing the pradhan's document ID
      const highestVoteUserQuery = userCollection
        .where(locQuery, "==", sachivAreaText)
        .where("level", "==", sachivAreaLevel)
        .orderBy("oneday_vote", "desc")
        .limit(1);

      const highestVoteUserSnapshot = await highestVoteUserQuery.get();
      console.log("Highest User For " + sachivData.locationText + ": " + highestVoteUserSnapshot.docs.length);

      if (!highestVoteUserSnapshot.empty) {
        const highestVotePost = highestVoteUserSnapshot.docs[0];
        const batch = admin.firestore().batch(); // Create a new batch

        const updateRef = sachivCollection.doc(sachiveDoc.id);
        console.log("Sachive Id: " + sachiveDoc.id);

        // Update area-sachive in the corresponding pradhan document
        batch.update(updateRef, {
          'sachiv_Id': highestVotePost.get("id") || "",
          "sachiv_model": {
            "fcm": highestVotePost.get("fcm") || "",
            "id": highestVotePost.get("id") || "",
            "image": highestVotePost.get("image") || "",
            "level": highestVotePost.get("level") || "",
            "name": highestVotePost.get("name") || "",
            "userdesc": highestVotePost.get("userdesc") || "",
            "username": highestVotePost.get("username") || ""
          }
        });

        // Commit the batch
        await batch.commit();
        console.log(`Area-sachive updated for pradhan: ${sachiveDoc.id}`);
      } else {
        console.log(`No qualifying post found for pradhan: ${sachivData.locationText}`);
      }
    }
    res.status(200).send('Area-sachive updated for all sachiv documents.');
  } catch (error) {
    console.error('Error updating area-sachive:', error);
    res.status(500).send('An error occurred while updating area-sachive.');
  }
});

exports.updateAreaPradhan = functions.runWith({ timeoutSeconds: 540, memory: '2GB' }).https.onRequest(async (req, res) => {
  try {
    const pradhanCollection = admin.firestore().collection('pradhan');
    const userCollection = admin.firestore().collection('users');

    const pradhanSnapshot = await pradhanCollection.get();
    const batch = admin.firestore().batch();

    // Loop through each Sachiv document
    for (const pradhanDoc of pradhanSnapshot.docs) {
      const pradhanData = pradhanDoc.data();


      if (pradhanData.org === true) {
        continue;
      }

      const pradhanAreaLevel = pradhanData.level;
      const pradhanAreaText = pradhanData.locationText;

      const previousPradhanFcmToken = pradhanData.pradhan_model?.fcm;
      const previousPradhanName = pradhanData.pradhan_model.name; // Name of the previous Pradhan

      console.log("pradhanAreaLevel: " + pradhanAreaLevel + ", pradhanAreaText: " + pradhanAreaText);

      var locQuery = "postal.text";
      switch (pradhanAreaLevel) {
        case 1:
          locQuery = "postal.text";
          break;
        case 2:
          locQuery = "city.text";
          break;
        case 3:
          locQuery = "state.text";
          break;
        case 4:
          locQuery = "country.text";
          break;
        default:
          locQuery = "postal.text";
          break;
      }

      console.log("locQuery: " + locQuery);

      // query users where the location matches the current pradhan area text and level matches the current pradhan area level
      // const highestVoteUserQuery = userCollection
      //   .where(locQuery, "==", pradhanAreaText)
      //   .where("level", "==", pradhanAreaLevel)
      //   .orderBy("upvote_count", "desc")
      //   .limit(1);

      // query for users where preferred election location is set to pradhan area text, if not set, then location matches the pradhan area text and level matches the pradhan area level
      const baseQuery = userCollection
        .where(
          Filter.or(
            Filter.where(
              'preferred_election_location.text',
              '==', pradhanAreaText,
            ),
            Filter.and(
              Filter.where(locQuery, '==', pradhanAreaText),
              Filter.where('level', '==', pradhanAreaLevel),
            ),
          ),
        )
        .orderBy("weekly_vote", 'desc');

      // to hold the query response
      let response = null

      // to figure out whether the loop iteration is first or follow up
      let isFirst = true

      // to hold the highest upvoted user doc
      let user = null

      // running a loop while we don't have a user
      while (user === null) {
        // if first iteration, get the initial docs
        if (isFirst) {
          isFirst = false

          response = await baseQuery.limit(5).get()
        } else {
          // otherwise get the next docs
          response = await baseQuery.startAfter(response.docs[response.docs.length - 1]).limit(5).get()
        }

        // if there are docs found
        if (response.docs.length !== 0) {
          // going through each doc
          for (let i = 0; i < response.docs.length; i++) {
            const doc = response.docs[i]

            // grabbing the doc data
            const docData = doc.data()

            // checking whether the key is present in the data or not
            const containsKey = docData['preferred_election_location'] !== undefined

            // checking current user is an organization or not
            const isOrg = docData['oadmin'] !== undefined

            // if key is not there, then the user doesn't have a preferred location and this is the default location, so add him
            // otherwise if the key is there and this is the preferred location of the user, add him
            if (!isOrg && (!containsKey || docData['preferred_election_location']['text'] === pradhanAreaText)) {
              user = doc

              // breaking the for loop
              break;
            }
          }
        } else {
          // if no more docs, break
          break
        }
      }

      // const highestVoteUserSnapshot = await highestVoteUserQuery.get();
      // console.log("Highest User For " + pradhanData.locationText + ": " + highestVoteUserSnapshot.docs.length);

      if (user !== null) {
        const batch = admin.firestore().batch(); // Create a new batch

        const updateRef = pradhanCollection.doc(pradhanDoc.id);
        console.log("Pradhan Id: " + pradhanDoc.id);
        console.log('new pradhaan name: ' + user.get('name'))
        console.log('weekly count: ' + user.get('weekly_vote'))

        // Update area-sachive in the corresponding pradhan document
        batch.update(updateRef, {
          'pradhan_id': user.get("id") || "",
          "pradhan_model": {
            "fcm": user.get("fcm") || "",
            "id": user.get("id") || "",
            "image": user.get("image") || "",
            "level": user.get("level") || "",
            "name": user.get("name") || "",
            "userdesc": user.get("userdesc") || "",
            "username": user.get("username") || "",
            "upvote_count": user.get("upvote_count") || 0,
            "weekly_vote": user.get("weekly_vote") || 0,

          },
          "pradhan_status": "",
          "voting": false,
        });

        // Commit the batch
        await batch.commit();
        console.log(`Area-pradhan updated for pradhan: ${pradhanDoc.id}`);
      } else {
        const batch = admin.firestore().batch(); // Create a new batch

        const updateRef = pradhanCollection.doc(pradhanDoc.id);
        console.log("Pradhan Id: " + pradhanDoc.id);

        // Update area-sachive in the corresponding pradhan document
        batch.update(updateRef, {
          'pradhan_id': "",
          "pradhan_model": {
            "fcm": "",
            "id": "",
            "image": "",
            "level": "",
            "name": "",
            "userdesc": "",
            "username": "",
            'upvote_count': 0,
            'weekly_vote': 0
          },
          "pradhan_status": "",
          "voting": false,
        });

        // Commit the batch
        await batch.commit();

        console.log(`No qualifying post found for pradhan: ${pradhanData.locationText}`);
      }
    }


    try {
      const organizationsSnapshot = await admin.firestore().collection("users").where("visibility", "in", ["Public", "Private"]).get();

      const batch = admin.firestore().batch();

      for (const org of organizationsSnapshot.docs) {
        try {
          const orgData = org.data();
          const usersWithVoteCounts = {};

          const postsSnapshot = await admin.firestore().collection("posts").where("user_id", "==", org.id).get();

          for (const post of postsSnapshot.docs) {
            const postData = post.data();
            let posterId = postData.poster_id || postData.user_id;

            if (usersWithVoteCounts[posterId]) {
              usersWithVoteCounts[posterId].vote += (postData.upvote_count || 0);
            } else {
              try {
                const userSnapshot = await admin.firestore().collection("users").doc(posterId).get();
                if (userSnapshot.exists) {
                  usersWithVoteCounts[posterId] = {
                    vote: postData.upvote_count || 0,
                    pradhan: { id: posterId, ...userSnapshot.data() },
                  };

                  const extraVoteSnapshot = await admin.firestore().collection("users").doc(org.id).collection('votes').doc(posterId).get();
                  if (extraVoteSnapshot && extraVoteSnapshot.exists) {
                    const extraVoterData = extraVoteSnapshot.data();
                    usersWithVoteCounts[posterId].vote += (extraVoterData.voters || []).length;

                    await extraVoteSnapshot.ref.delete();
                  }
                }
              } catch (error) {
                console.log(`Error while getting user ${posterId}:`, error);
              }
            }
          }

          // Sorting users by vote count in descending order
          const sortedUsers = Object.values(usersWithVoteCounts).sort((a, b) => (b.vote || 0) - (a.vote || 0));
          const updateRef = pradhanCollection.doc(org.id);

          if (sortedUsers.length > 0) {
            const topUser = sortedUsers[0];
            const data = {
              pradhan_id: topUser?.pradhan?.id || "",
              pradhan_model: {
                fcm: topUser?.pradhan?.fcm || "",
                id: topUser?.pradhan?.id || "",
                image: topUser?.pradhan?.image || "",
                level: topUser?.pradhan?.level || "",
                name: topUser?.pradhan?.name || "",
                userdesc: topUser?.pradhan?.userdesc || "",
                username: topUser?.pradhan?.username || "",
              },
              pradhan_status: "",
              voting: false,
              org: true,
            };
            batch.set(updateRef, data, { merge: true });
          } else {
            batch.set(updateRef, {
              'pradhan_id': "",
              "pradhan_model": {
                "fcm": "",
                "id": "",
                "image": "",
                "level": "",
                "name": "",
                "userdesc": "",
                "username": ""
              },
              "pradhan_status": "",
              "voting": false,
              "org": true
            }, { merge: true });
          }
        } catch (error) {
          console.log(`Error while processing organization: ${error}`);
        }
      }
      await batch.commit();



    } catch (error) {
      console.log("Error while getting organizations:", error);
    }

    res.status(200).send('Area-pradhan updated for all pradhan documents.');
  } catch (error) {
    console.error('Error updating area-pradhan:', error);
    res.status(500).send(`An error occurred while updating area-pradhan. ${error}`);
  }
});

///////dummy data pass... 5/5/25,7:15pm
//exports.calculatePayments = functions.runWith({ timeoutSeconds: 60, memory: '1GB' }).https.onRequest(async (req, res) => {
//  // Dummy data for multiple pradhaans with different amounts
//  const pradhaans = [
//    { id: 'pradhan_1', name: 'Pradhan One', amount: 150 }, // Custom amount
//    { id: 'pradhan_2', name: 'Pradhan Two', amount: 100 }, // Custom amount
//    { id: 'pradhan_3', name: 'Pradhan Three', amount: 50 }  // Custom amount
//  ];
//  const dummyDate = new Date().toISOString().split('T')[0]; // Today's date (YYYY-MM-DD)
//  const uniqueId = Date.now().toString(); // Unique ID for each call
//
//  console.log(`[TEST] Starting payout data store for ${pradhaans.length} pradhaans with uniqueId: ${uniqueId}`);
//
//  // Firestore batch for updates
//  const batch = admin.firestore().batch();
//
//  // Har pradhan ke liye payout data store karo
//  pradhaans.forEach((pradhan) => {
//    const pradhanId = pradhan.id;
//    const pradhanName = pradhan.name;
//    const amount = pradhan.amount;
//
//    // Payout entry: Date-based document ke andar pradhaans sub-collection mein pradhanId document
//    const payoutRef = admin.firestore().collection('payouts').doc(`payout_${dummyDate}_${uniqueId}`);
//    const pradhaanPayoutRef = payoutRef.collection('pradhaans').doc(pradhanId);
//    const payoutData = {
//      user_id: pradhanId,
//      pradhan_name: pradhanName,
//      amount_due: amount,
//      status: 'pending',
//      created_at: FieldValue.serverTimestamp(),
//      updated_at: FieldValue.serverTimestamp(),
//      uniqueId: uniqueId // Track karne ke liye
//    };
//    batch.set(pradhaanPayoutRef, payoutData);
//    console.log(`[TEST] Payout queue kiya for ${pradhanId} with uniqueId ${uniqueId}:`, JSON.stringify(payoutData, null, 2));
//  });
//
//  // Batch commit karo
//  try {
//    console.log(`[TEST] Firestore batch commit kar rahe hain for uniqueId: ${uniqueId}`);
//    await batch.commit();
//    console.log(`[TEST] Payout data successfully stored for ${pradhaans.length} pradhaans with uniqueId: ${uniqueId}`);
//    return res.status(200).send({ message: `Payout data stored successfully for ${pradhaans.length} pradhaans with uniqueId: ${uniqueId}` });
//  } catch (error) {
//    console.error(`[TEST] Batch commit failed for uniqueId: ${uniqueId}:`, error);
//    return res.status(500).send({ message: `Failed to store payout data: ${error.message}` });
//  }
//});

//async function getScopeTree(scope, level, allPradhans) {
//  console.log(`[TEST] getScopeTree called for scope=${scope}, level=${level}`);
//  const result = new Map();
//  const pradhanData = allPradhans.find((pradhan) => pradhan.id === scope)?.data();
//  if (pradhanData) {
//    result.set(scope, pradhanData.pradhan_model?.upvote_count || 100);
//  }
//  return result;
//}

///live running code.....
//change on 18*5*25

/*
exports.calculatePayments = functions.runWith({ timeoutSeconds: 540, memory: '2GB' }).https.onRequest(async (req, res) => {
  // Creates start of week to fetch this week's all views
  const today = new Date();
  if (today.getDay() === 0) {
    today.setDate(today.getDate() - 7);
  } else {
    today.setDate(today.getDate() - today.getDay());
  }

  const startOfWeek = new Date(today);
  startOfWeek.setHours(22, 0, 0, 0);

  const check = await admin.firestore().collection("pradhan_history").where('time', '>=', startOfWeek).get();
  if (!check.empty) {
    return res.status(200).send({ message: `Calculations already performed for ${startOfWeek}` });
  }

  // Get all the views from current week
  const thisWeekViews = await admin.firestore().collection('views').where('created_at', '>=', startOfWeek).get();

  if (thisWeekViews.empty) {
    return res.status(200).send({ message: `This week has no earnings [${startOfWeek}]` });
  }

  const adsAndViewsMatrix = new Map();
  const uniqueAdIds = new Set();

  thisWeekViews.docs.forEach((view, index) => {
    const { scope, ad_id } = view.data() || {};

    if (!adsAndViewsMatrix.has(scope)) {
      adsAndViewsMatrix.set(scope, new Map());
    }

    if (!uniqueAdIds.has(ad_id)) {
      uniqueAdIds.add(ad_id);
    }

    const countMap = adsAndViewsMatrix.get(scope);
    countMap.set(ad_id, (countMap.get(ad_id) || 0) + 1);
  });

  // // Get ad details
  const allAdIds = [...uniqueAdIds];
  const batchSize = 10;
  const batches = [];
  for (let i = 0; i < allAdIds.length; i += batchSize) {
    const batchIds = allAdIds.slice(i, i + batchSize);
    const batchQuery = admin.firestore().collection('ads').where('id', 'in', batchIds).get();
    batches.push(batchQuery);
  }

  const adSnapshots = await Promise.all(batches);
  const adDetails = adSnapshots.flatMap((snapshot) => snapshot.docs);

  // Calculate amount for each ad
  const scopeWithEarningMatrix = new Map();
  Array.from(adsAndViewsMatrix.entries()).forEach(([scopeId, viewCounts]) => {
    const totalScopeAmount = Array.from(viewCounts.entries()).map(([adId, count]) => {
      const { proposed_amount = 0, target_views = 1 } = adDetails.find((detail) => detail.id === adId).data();
      const amount = (count * proposed_amount) / target_views;
      return amount;
    }).reduce((a, b) => a + b);
    scopeWithEarningMatrix.set(scopeId, totalScopeAmount);
  });

  // Distribute amount to level and sub levels
  // Task is to get all the sub levels and their total votes including parent scope
  // Then sum all votes and create ratio for each level and divide amount accordingly
  const allPradhaans = await admin.firestore().collection('pradhan').get();

  const batch = admin.firestore().batch();

  const tasks = Array.from(scopeWithEarningMatrix.entries()).map(async ([scopeId, totalAmount]) => {
    const pradhanData = allPradhaans.docs.find((pradhan) => pradhan.id === scopeId)?.data() || {};
    const tree = await getScopeTree(scopeId, pradhanData.level || 1, allPradhaans.docs);

    // Calculate total votes
    const totalVotes = Array.from(tree.values()).reduce((sum, votes) => sum + votes, 0) || 1;

    // Distribute amount based on votes ratio
    const distributedTree = new Map(
      Array.from(tree.entries()).map(([subScopeId, votes]) => {
        const distributedAmount = (votes / totalVotes) * totalAmount;
        return [subScopeId, distributedAmount];
      })
    );

    // 🔥 Save Data in Firestore (Wallet + History)
//    for (const [scope, amount] of distributedTree.entries()) {
//      const pradhanId = allPradhaans.docs.find((pradhan) => pradhan.id === scope)?.data()?.pradhan_id || "admin";

for (const [scope, amount] of distributedTree.entries()) {
        const pradhanDoc = allPradhaans.docs.find((pradhan) => pradhan.id === scope);
        const pradhanData = pradhanDoc?.data() || {};
        const pradhanId = pradhanData.pradhan_id || "admin";


if(amount<=0)continue;
const userSnapshot = await admin.firestore().collection('users').doc(pradhanId).get();
const userData = userSnapshot.exists ? userSnapshot.data() : {};
const bankSnapshot = await admin.firestore().collection('bankdetails').doc(pradhanId).get();
const bankData = bankSnapshot.exists ? bankSnapshot.data() : {};

const walletRef = admin.firestore().collection('wallets').doc(pradhanId);
        batch.set(walletRef, {
          amount: FieldValue.increment(amount),
          used_amount: FieldValue.increment(0),
        }, { merge: true });

// Create Payout Entry
        const payoutRef = admin.firestore()
          .collection('payouts')
          .doc(`payout_${startOfWeek.toISOString().split('T')[0]}`);
        const pradhaanPayoutRef = payoutRef.collection('pradhaan_payouts').doc(pradhanId);

        const payoutData = {
          user_id: pradhanId,
          pradhan_name: userData.name || 'Unknown',
          level: pradhanData.level || 1,
          full_address: userData.city ? [
            userData.postal?.name || '',
            userData.city?.name || '',
            userData.state?.name || '',
            userData.country?.name || ''
          ].filter(Boolean) : [],
          bank_details: {
            bank_name: bankData.bank_name || '',
            account_number: bankData.account_number || '',
            ifsc_number: bankData.ifsc_number || '',
            your_name: bankData.your_name || '',
            bank_address: bankData.bank_address || ''
          },
          amount_due: amount,
          transaction_id: null,
          remark: null,
          status: 'pending',
          send_date: FieldValue.serverTimestamp(),
          created_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          scope: scope,
        };

        batch.set(pradhaanPayoutRef, payoutData);

//      if (amount > 0) {
//        // Update Wallet (Only if amount > 0)
//        const walletRef = admin.firestore().collection('wallets').doc(pradhanId);
//        batch.set(walletRef, { amount: FieldValue.increment(amount) }, { merge: true });
//}


// change by ygTest
*/
/*
//Fetch Pradhaan and Bank Details
const userDoc = admin.firestore().collection('users').doc(pradhaanID).get();
const bankDoc=admin.firestore().collection("bankdetails").doc(pradhaanID).get();

const userData=userDoc.exists ? userDoc.data():{};
const bankData=bankDoc.exists ? bankDoc.data() : {};

//create Payout Entry
const payoutRef= admin.firestore().collection('payouts').doc();
const pradhaanPayoutRef= payoutRef.collection('pradhaan_payouts').doc(pradhaanID);

const payoutData={
user_id:pradhaanID,
pradhan_name:userData.name : "UnKnown",
pradhan_details: {
            image: userData.image || '',
            level: userData.level || 1,
            userdesc: userData.userdesc || '',
          },

        location: {
                 id: scope,
                 name: pradhanData.locationText || scope,
               },
                    amount_due:amount,
                    bank_detail:{
                        bank_name: bankData.bank_name || '',
                                account_number: bankData.account_number || '',
                                ifsc: bankData.ifsc_number || '',
                                bank_address: bankData.bank_address || '',
                                your_name: bankData.your_name || '',
                    }
                    transaction_id:null,
                    remark:"",
                    status: 'pending',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          };

          batch.set(pradhaanPayoutRef, payoutData);
}*//*


      // Always Add History Record
      const historyRef = admin.firestore().collection('pradhan_history').doc();
      batch.set(historyRef, { pradhanId, scope: scopeId, amount, time: startOfWeek });
    }

    return [scopeId, distributedTree];
  });

  const resultArray = await Promise.all(tasks);
  const result = new Map(resultArray);

  // 🔥 Commit All Changes at Once
  await batch.commit();

  console.log("Final Result:", Object.fromEntries(result));

  return res.status(200).send({ data: Array.from(scopeWithEarningMatrix.entries()) });
});
*/


//change on 18*5*25
// exports.calculatePayments = functions.runWith({ timeoutSeconds: 540, memory: '2GB' }).https.onRequest(async (req, res) => {
//   // Creates start of week to fetch this week's all views
//   const today = new Date();
//   if (today.getDay() === 0) {
//     today.setDate(today.getDate() - 2);
//   } else {
//     today.setDate(today.getDate() - 2);
//   }

//   const startOfWeek = new Date(today);
//   startOfWeek.setHours(14, 57, 20, 0);

//   const check = await admin.firestore().collection("pradhan_history").where('time', '>=', startOfWeek).get();
//   if (!check.empty) {
//     return res.status(200).send({ message: `Calculations already performed for ${startOfWeek}` });
//   }

//   // Get all the views from current week
//   const thisWeekViews = await admin.firestore().collectionGroup('viewers').where('created_at', '>=', startOfWeek).orderBy('created_at', 'asc').get();

//   if (thisWeekViews.empty) {
//     return res.status(200).send({ message: `This week has no earnings [${startOfWeek}]` });
//   }
//   console.log('find this week , its not empty');
//   const adsAndViewsMatrix = new Map();
//   const uniqueAdIds = new Set();

//   thisWeekViews.docs.forEach((view, index) => {
//     const { scope, ad_id } = view.data() || {};

//     if (!adsAndViewsMatrix.has(scope)) {
//       adsAndViewsMatrix.set(scope, new Map());
//     }
//     console.log('adsand ciews matrix: data fetched: ', adsAndViewsMatrix);

//     if (!uniqueAdIds.has(ad_id)) {
//       uniqueAdIds.add(ad_id);
//     }
//     console.log('uniqueAdIds get done: ', uniqueAdIds);
//     const countMap = adsAndViewsMatrix.get(scope);
//     countMap.set(ad_id, (countMap.get(ad_id) || 0) + 1);
//     console.log('countmap finding done: ', countMap);
//   });

//   // Get ad details
//   const allAdIds = [...uniqueAdIds];
//   console.log("all ad Ids: ", allAdIds);
//   const batchSize = 10;
//   const batches = [];
//   for (let i = 0; i < allAdIds.length; i += batchSize) {
//     const batchIds = allAdIds.slice(i, i + batchSize);
//     const batchQuery = admin.firestore().collection('ads').where('id', 'in', batchIds).get();
//     batches.push(batchQuery);
//   }

//   const adSnapshots = await Promise.all(batches);
//   const adDetails = adSnapshots.flatMap((snapshot) => snapshot.docs);

//   // Calculate amount for each ad
//   console.log('starting calculating  amount for each...');
//   const scopeWithEarningMatrix = new Map();
//   Array.from(adsAndViewsMatrix.entries()).forEach(([scopeId, viewCounts]) => {
//     const totalScopeAmount = Array.from(viewCounts.entries()).map(([adId, count]) => {
//       const adDetail = adDetails.find((detail) => detail.id === adId);
//       if (!adDetail) {
//         console.warn(`Ad not found for adId ${adId} in scope ${scopeId}`);
//         return 0;
//       }
//       const { proposed_amount = 0, target_views = 1 } = adDetail.data();
//       const amount = (count * proposed_amount) / target_views;
//       return amount;
//     }).reduce((a, b) => a + b, 0);
//     scopeWithEarningMatrix.set(scopeId, totalScopeAmount);
//   });
//   console.log('finish calculating  amount for each ...');

//   // Distribute amount to level and sub levels
//   const allPradhaans = await admin.firestore().collection('pradhan').get();
//   console.log("all pradhans fetching: ");
//   const batch = admin.firestore().batch();

//   const tasks = Array.from(scopeWithEarningMatrix.entries()).map(async ([scopeId, totalAmount]) => {
//     const pradhanData = allPradhaans.docs.find((pradhan) => pradhan.id === scopeId)?.data() || {};
//     const tree = await getScopeTree(scopeId, pradhanData.level || 1, allPradhaans.docs);

//     if (tree.size === 0) {
//       console.log(`No pradhan or votes for scope ${scopeId}, skipping`);
//       return [scopeId, new Map()];
//     }

//     // Validate totalAmount
//     if (totalAmount <= 0) {
//       console.warn(`Invalid totalAmount ${totalAmount} for scope ${scopeId}`);
//       return [scopeId, new Map()];
//     }

//     // Calculate total votes
//     const totalVotes = Array.from(tree.values()).reduce((sum, votes) => sum + votes, 0) || 1;
//     if (totalVotes === 0) {
//       console.warn(`No votes found for scope ${scopeId}`);
//       return [scopeId, new Map()];
//     }
//     console.log("total votes: ", totalVotes);

//     // Distribute amount based on votes ratio
//     console.log("starting distribute amount based on votes.......");
//     const distributedTree = new Map(
//       Array.from(tree.entries()).map(([subScopeId, votes]) => {
//         const distributedAmount = (votes / totalVotes) * totalAmount;
//         return [subScopeId, distributedAmount];
//       })
//     );
//     console.log("distribute amount based on votes ratio...finish");

//     // Save Data in Firestore (Wallet + History)
//     for (const [scope, amount] of distributedTree.entries()) {
//       const pradhanDoc = allPradhaans.docs.find((pradhan) => pradhan.id === scope);
//       const pradhanData = pradhanDoc?.data() || {};
//       const pradhanId = pradhanData.pradhan_id || "admin";
//       console.log("save data to firebase:.................");

//       if (amount <= 0) {
//         console.log("amount is <=0, process skip for it");
//         continue;
//       }

//       const userSnapshot = await admin.firestore().collection('users').doc(pradhanId).get();
//       const userData = userSnapshot.exists ? userSnapshot.data() : {};
//       const bankSnapshot = await admin.firestore().collection('bankdetails').doc(pradhanId).get();
//       const bankData = bankSnapshot.exists ? bankSnapshot.data() : {};
//       const walletRef = admin.firestore().collection('wallets').doc(pradhanId);
//       batch.set(walletRef, {
//         amount: FieldValue.increment(amount),
//         used_amount: FieldValue.increment(amount),
//       }, { merge: true });
//       console.log('wallet updated: ...............');

//       // Create Payout Entry
//       const payoutRef = admin.firestore().collection('payouts').doc(`payout_${startOfWeek.toISOString().split('T')[0]}`);
//       const pradhaanPayoutRef = payoutRef.collection('pradhaan_payouts').doc(pradhanId);
//       const pradhanLocData=pradhaanPayoutRef.collection('locations').doc(scope);
//     // let  pradhanTotalAmount=(await pradhaanPayoutRef.get()).data().total_amount;
//     //    console.log("pradhanTotalAmount: ",pradhanTotalAmount, 'amount :',amount);
//     //   pradhanTotalAmount += Number(amount);
//     //    console.log("after pradhanTotalAmount: ",pradhanTotalAmount, 'amount :',amount);

// const snapshot = await pradhaanPayoutRef.get();
// let pradhanTotalAmount = Number(snapshot.exists ? snapshot.data().total_amount : 0);

// console.log("pradhanTotalAmount: ", pradhanTotalAmount, 'amount:', amount);

// pradhanTotalAmount += Number(amount);

// console.log("after pradhanTotalAmount:", pradhanTotalAmount, 'amount:', amount);


//       const totalPayoutData = {
//         user_id: pradhanId,
//         pradhan_name: userData.name || 'Unknown',
//         level: pradhanData.level || 1,
//         full_address: userData.city ? [
//           userData.postal?.name || '',
//           userData.city?.name || '',
//           userData.state?.name || '',
//           userData.country?.name || ''
//         ].filter(Boolean) : [],
//         bank_details: {
//           bank_name: bankData.bank_name || '',
//           account_number: bankData.account_number || '',
//           ifsc_number: bankData.ifsc_number || '',
//           your_name: bankData.your_name || '',
//           bank_address: bankData.bank_address || ''
//         },
//         total_amount: pradhanTotalAmount,
//         transaction_id: null,
//         remark: null,
//         status: 'pending',
//         send_date: FieldValue.serverTimestamp(),
//         created_at: FieldValue.serverTimestamp(),
//         updated_at: FieldValue.serverTimestamp(),
//       //  scope: scope,
//       };

//       batch.set(pradhaanPayoutRef, totalPayoutData),{merge:true};

//       const payoutData = {
//         user_id: pradhanId,
//         pradhan_name: userData.name || 'Unknown',
//         level: pradhanData.level || 1,
//         full_address: userData.city ? [
//           userData.postal?.name || '',
//           userData.city?.name || '',
//           userData.state?.name || '',
//           userData.country?.name || ''
//         ].filter(Boolean) : [],
//         bank_details: {
//           bank_name: bankData.bank_name || '',
//           account_number: bankData.account_number || '',
//           ifsc_number: bankData.ifsc_number || '',
//           your_name: bankData.your_name || '',
//           bank_address: bankData.bank_address || ''
//         },
//         amount_due: amount,
//         transaction_id: null,
//         remark: null,
//         status: 'pending',
//         send_date: FieldValue.serverTimestamp(),
//         created_at: FieldValue.serverTimestamp(),
//         updated_at: FieldValue.serverTimestamp(),
//         scope: scope,
//       };

//             batch.set(pradhanLocData, payoutData);

//       console.log('payout created: .................');

//       // Always Add History Record
//       const historyRef = admin.firestore().collection('pradhan_history').doc();
//       batch.set(historyRef, { pradhanId, scope: scopeId, amount, time: startOfWeek });
//     }

//     return [scopeId, distributedTree];
//   });

//   const resultArray = await Promise.all(tasks);
//   const result = new Map(resultArray);

//   // Commit All Changes at Once
//   await batch.commit();

//   console.log("Final Result:", Object.fromEntries(result));

//   return res.status(200).send({ data: Array.from(scopeWithEarningMatrix.entries()) });
// });


//////****************** */
/*
exports.resetVote = functions.https.onRequest(async (req, res) => {
try {
        const snapshot = await admin.firestore().collection("users").get();

        let batch = admin.firestore().batch();
        let counter = 0;

        for (const doc of snapshot.docs) {
          batch.update(doc.ref, { weekly_vote: 0 });
          counter++;

          if (counter === 500) {
            await batch.commit();
            console.log(`✅ Committed 500 docs`);
            batch = admin.firestore().batch();
            counter = 0;
          }
        }

        if (counter > 0) {
          await batch.commit();
          console.log(`✅ Committed remaining ${counter} docs`);
        }
        const afterReset = await admin.firestore()
              .collection('users')
              .doc('docid')
              .get();
              console.log('dada');
            return res.status(200).send({
              message: `weekly votes of ${afterReset.data()?.weekly_vote}`
            });

      } catch (error) {
        console.error(error);
        return res.status(500).send({ error: error.message });
      }
});
exports.setvVote = functions.https.onRequest(async (req, res) => {
try {
        await admin.firestore()
          .collection("users")
          .doc("TrBiVPQ8KqYLkxZNqwvQcM1CFLr1")
          .set({
            weekly_vote: 10,
          });
         let vote =  await admin.firestore()
                        .collection('users')
                        .doc('docid')
                        .get();
                        console.log('dada');
                      return res.status(200).send({
                        message: `weekly votes of ${vote.data()?.weekly_vote}`
                      });

      } catch (error) {
        console.error(error);
        return res.status(500).send({ error: error.message });
      }
});
*/

exports.calculatePayments = functions.runWith({ timeoutSeconds: 540, memory: '2GB' }).https.onRequest(async (req, res) => {
  // Creates start of week to fetch this week's all views
  const today = new Date();
  if (today.getDay() === 0) {
    today.setDate(today.getDate() - 7);
  } else {
    today.setDate(today.getDate() - today.getDate());
  }

  const startOfWeek = new Date(today);
  startOfWeek.setHours(22, 0, 0, 0);

  const check = await admin.firestore().collection("pradhan_history").where('time', '>=', startOfWeek).get();
  if (!check.empty) {
    return res.status(200).send({ message: `Calculations already performed for ${startOfWeek}` });
  }

  // Get all the views from current week
  const thisWeekViews = await admin.firestore().collectionGroup('viewers').where('created_at', '>=', startOfWeek).orderBy('created_at', 'asc').get();

  if (thisWeekViews.empty) {
    return res.status(200).send({ message: `This week has no earnings [${startOfWeek}]` });
  }
  console.log('find this week , its not empty');
  const adsAndViewsMatrix = new Map();
  const uniqueAdIds = new Set();

  thisWeekViews.docs.forEach((view, index) => {
    const { scope, ad_id } = view.data() || {};

    if (!adsAndViewsMatrix.has(scope)) {
      adsAndViewsMatrix.set(scope, new Map());
    }
    console.log('adsand ciews matrix: data fetched: ', adsAndViewsMatrix);

    if (!uniqueAdIds.has(ad_id)) {
      uniqueAdIds.add(ad_id);
    }
    console.log('uniqueAdIds get done: ', uniqueAdIds);
    const countMap = adsAndViewsMatrix.get(scope);
    countMap.set(ad_id, (countMap.get(ad_id) || 0) + 1);
    console.log('countmap finding done: ', countMap);
  });

  // Get ad details
  const allAdIds = [...uniqueAdIds];
  console.log("all ad Ids: ", allAdIds);
  const batchSize = 10;
  const batches = [];
  for (let i = 0; i < allAdIds.length; i += batchSize) {
    const batchIds = allAdIds.slice(i, i + batchSize);
    const batchQuery = admin.firestore().collection('ads').where('id', 'in', batchIds).get();
    batches.push(batchQuery);
  }

  const adSnapshots = await Promise.all(batches);
  const adDetails = adSnapshots.flatMap((snapshot) => snapshot.docs);

  // Calculate amount for each ad
  console.log('starting calculating  amount for each...');
  const scopeWithEarningMatrix = new Map();
  Array.from(adsAndViewsMatrix.entries()).forEach(([scopeId, viewCounts]) => {
    const totalScopeAmount = Array.from(viewCounts.entries()).map(([adId, count]) => {
      const adDetail = adDetails.find((detail) => detail.id === adId);
      if (!adDetail) {
        console.warn(`Ad not found for adId ${adId} in scope ${scopeId}`);
        return 0;
      }
      const { proposed_amount = 0, target_views = 1 } = adDetail.data();
      const amount = (count * proposed_amount) / target_views;
      return amount;
    }).reduce((a, b) => a + b, 0);
    scopeWithEarningMatrix.set(scopeId, totalScopeAmount);
  });
  console.log('finish calculating  amount for each ...');

  // Distribute amount to level and sub levels
  const allPradhaans = await admin.firestore().collection('pradhan').get();
  console.log("all pradhans fetching: ");
  const batch = admin.firestore().batch();

  // Map to aggregate amounts for each pradhanId
  const pradhanPayouts = new Map(); // Map<pradhanId, { totalAmount, scopes }>

  const tasks = Array.from(scopeWithEarningMatrix.entries()).map(async ([scopeId, totalAmount]) => {
    const pradhanData = allPradhaans.docs.find((pradhan) => pradhan.id === scopeId)?.data() || {};
    const tree = await getScopeTree(scopeId, pradhanData.level || 1, allPradhaans.docs);

    if (tree.size === 0) {
      console.log(`No pradhan or votes for scope ${scopeId}, skipping`);
      return [scopeId, new Map()];
    }
    // Validate totalAmount
    if (totalAmount <= 0) {
      console.warn(`Invalid totalAmount ${totalAmount} for scope ${scopeId}`);
      return [scopeId, new Map()];
    }

    // Calculate total votes
    const totalVotes = Array.from(tree.values()).reduce((sum, votes) => sum + votes, 0) || 1;
    if (totalVotes === 0) {
      console.warn(`No votes found for scope ${scopeId}`);
      return [scopeId, new Map()];
    }
    console.log("total votes: ", totalVotes);

    // Distribute amount based on votes ratio
    console.log("starting distribute amount based on votes.......");
    const distributedTree = new Map(
      Array.from(tree.entries()).map(([subScopeId, votes]) => {
        const distributedAmount = (votes / totalVotes) * totalAmount;
        return [subScopeId, distributedAmount];
      })
    );
    console.log("distribute amount based on votes ratio...finish");

    // Save Data in Firestore (Wallet + History)
    for (const [scope, amount] of distributedTree.entries()) {
      const pradhanDoc = allPradhaans.docs.find((pradhan) => pradhan.id === scope);
      const pradhanData = pradhanDoc?.data() || {};
      const pradhanId = pradhanData.pradhan_id || "admin";
      console.log("save data to firebase:.................");

      if (amount <= 0) {
        console.log("amount is <=0, process skip for it");
        continue;
      }

      const userSnapshot = await admin.firestore().collection('users').doc(pradhanId).get();
      const userData = userSnapshot.exists ? userSnapshot.data() : {};
      const bankSnapshot = await admin.firestore().collection('bankdetails').doc(pradhanId).get();
      const bankData = bankSnapshot.exists ? bankSnapshot.data() : {};

      // Aggregate amounts in pradhanPayouts Map
      if (!pradhanPayouts.has(pradhanId)) {
        pradhanPayouts.set(pradhanId, {
          totalAmount: 0,
          scopes: new Map(),
        });
      }

      const pradhanEntry = pradhanPayouts.get(pradhanId);
      pradhanEntry.totalAmount += Number(amount); // Add amount to total
      const currentScopeAmount = pradhanEntry.scopes.get(scope) || 0;
      pradhanEntry.scopes.set(scope, currentScopeAmount + Number(amount)); // Add amount to scope

      const walletRef = admin.firestore().collection('wallets').doc(pradhanId);
      batch.set(walletRef, {
        amount: FieldValue.increment(amount),
        used_amount: FieldValue.increment(amount),
      }, { merge: true });
      console.log('wallet updated: ...............');

      // Create Payout Entry
      const payoutRef = admin.firestore().collection('payouts').doc(`payout_${startOfWeek.toISOString().split('T')[0]}`);
      const pradhaanPayoutRef = payoutRef.collection('pradhaan_payouts').doc(pradhanId);
      const pradhanLocData = pradhaanPayoutRef.collection('locations').doc(scope);

      console.log("pradhanTotalAmount: ", pradhanEntry.totalAmount, 'amount:', amount);

      const totalPayoutData = {
        user_id: pradhanId,
        pradhan_name: userData.name || 'Unknown',
        level: pradhanData.level || 1,
        full_address: userData.city ? [
          userData.postal?.name || '',
          userData.city?.name || '',
          userData.state?.name || '',
          userData.country?.name || ''
        ].filter(Boolean) : [],
        bank_details: {
          bank_name: bankData.bank_name || '',
          account_number: bankData.account_number || '',
          ifsc_number: bankData.ifsc_number || '',
          your_name: bankData.your_name || '',
          bank_address: bankData.bank_address || ''
        },
        total_amount: pradhanEntry.totalAmount, // Total amount for this pradhanId
        transaction_id: null,
        remark: null,
        status: 'pending',
        send_date: FieldValue.serverTimestamp(),
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      };

      batch.set(pradhaanPayoutRef, totalPayoutData, { merge: true });

      const payoutData = {
        user_id: pradhanId,
        pradhan_name: userData.name || 'Unknown',
        level: pradhanData.level || 1,
        full_address: userData.city ? [
          userData.postal?.name || '',
          userData.city?.name || '',
          userData.state?.name || '',
          userData.country?.name || ''
        ].filter(Boolean) : [],
        bank_details: {
          bank_name: bankData.bank_name || '',
          account_number: bankData.account_number || '',
          ifsc_number: bankData.ifsc_number || '',
          your_name: bankData.your_name || '',
          bank_address: bankData.bank_address || ''
        },
        amount_due: pradhanEntry.scopes.get(scope), // Total amount for this scope
        transaction_id: null,
        remark: null,
        status: 'pending',
        send_date: FieldValue.serverTimestamp(),
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        scope: scope,
      };

      batch.set(pradhanLocData, payoutData, { merge: true });

      console.log('payout created: .................');

      // Always Add History Record
      const historyRef = admin.firestore().collection('pradhan_history').doc();
      batch.set(historyRef, { pradhanId, scope: scopeId, amount, time: startOfWeek });
    }

    return [scopeId, distributedTree];
  });

  const resultArray = await Promise.all(tasks);
  const result = new Map(resultArray);

  // Commit All Changes at Once
  await batch.commit();

  console.log("Final Result:", Object.fromEntries(result));

  return res.status(200).send({ data: Array.from(scopeWithEarningMatrix.entries()) });
});
///////////***********/////// */

// Old getScopeTree (using location collection)
async function getScopeTree(scopeId, level, allPradhans) {
  console.log(`getScopeTree called for scopeId: ${scopeId}, level: ${level}`);
  
  const levelMap = {
    3: 'State',
    2: 'city',
    1: 'postal'
  };

  const result = new Map();

  async function recurse(ref, currentLevel) {
    const id = ref.id;
    const pradhanDoc = allPradhans.find(p => p.id === id);
    if (pradhanDoc) {
    //Getting weekly vote instead of upvote_count to distribute amount on the basis weekly votes
      //const votes = pradhanDoc.data()?.pradhan_model?.upvote_count || 0;
      const votes = pradhanDoc.data()?.pradhan_model?.weekly_vote || 0;
      result.set(id, votes);
    }

    if (currentLevel <= 1) return;

    const nextCollection = levelMap[currentLevel - 1];
    if (!nextCollection) return;

    const snapshot = await ref.collection(nextCollection).get();
    for (const doc of snapshot.docs) {
      await recurse(doc.ref, currentLevel - 1);
    }
  }

  let rootRef = admin.firestore().collection('location').doc('1-India');

  if (level >= 3) {
    const stateSnap = await rootRef.collection('State').doc(scopeId).get();
    if (!stateSnap.exists) return result;
    await recurse(stateSnap.ref, level);
  } else if (level === 2) {
    const statesSnap = await rootRef.collection('State').get();
    for (const state of statesSnap.docs) {
      const citySnap = await state.ref.collection('city').doc(scopeId).get();
      if (citySnap.exists) {
        await recurse(citySnap.ref, level);
        break;
      }
    }
  } else if (level === 1) {
    const statesSnap = await rootRef.collection('State').get();
    for (const state of statesSnap.docs) {
      const citiesSnap = await state.ref.collection('city').get();
      for (const city of citiesSnap.docs) {
        const postalSnap = await city.ref.collection('postal').doc(scopeId).get();
        if (postalSnap.exists) {
          await recurse(postalSnap.ref, level);
          break;
        }
      }
    }
  }

  console.log(`getScopeTree complete for ${scopeId}:`, Object.fromEntries(result));
  return result;
}

async function searchRefByBatch(group, fieldName, fieldValue) {
  const db = admin.firestore();
  let lastDoc = null;
  let hasMore = true;
  const batchSize = 15;

  while (hasMore) {
    let query = db.collectionGroup(group).limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    try {
      const snapshot = await query.get();
      if (snapshot.empty) {
        console.log('No more documents to fetch.');
        hasMore = false;
        break;
      }

      for (const data of snapshot.docs) {
        const dataRaw = data.data();
        if (dataRaw[fieldName] == fieldValue) {
          return { docs: [data] };
        }
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < batchSize) {
        hasMore = false;
      }
    } catch (error) {
      console.error("Error searching by batch:", error);
      hasMore = false;
    }
  }

  return undefined;
}
// async function getScopeTree(scope, level, allPradhans, rootRef) {
//   console.log(`called getScopeTree(${scope}, ${level}, ${rootRef?.path})`);
//   try{
//   const scopes = { 1: 'postal', 2: 'city', 3: 'State', 4: '' };

//   if (level < 1) return new Map(); // Base case

//   const result = new Map();
//   const groupName = scopes[level];

//   let snapshotPromise;
//   if (groupName === "") {
//     snapshotPromise = admin.firestore().collection('location').doc(scope).get();
//   } else if (rootRef) {
//     snapshotPromise = rootRef.collection(groupName).where(FieldPath.documentId(), '==', scope).get();
//   } else {
//     snapshotPromise = searchRefByBatch(groupName, 'id', scope);
//   }

//   const snapshot = await snapshotPromise;
//   const docs = snapshot.docs || [snapshot]; // Handle both single doc & multiple docs

//   const fetchPromises = docs.map(async (doc) => {
//     const id = doc.data().id;
//     console.log('passed level', id);

//     const pradhanData = allPradhans.find((pradhan) => pradhan.id === id)?.data();
//     if (pradhanData) {
//       result.set(id, pradhanData.pradhan_model?.upvote_count || 0);

//       if (level > 1) {
//         const locationsSnapshot = await doc.ref.collection(scopes[level - 1]).get();
//         const subPromises = locationsSnapshot.docs.map((loc) =>
//           getScopeTree(loc.id, level - 1, allPradhans, doc.ref)
//         );

//         const subResults = await Promise.all(subPromises);
//         subResults.forEach((subResult) => {
//           subResult.forEach((val, key) => result.set(key, val));
//         });
//       }
//     }
//   });

//   await Promise.all(fetchPromises);

//   console.log("result:", Object.fromEntries(result));
//   return result;
// }catch(e){
//   console.log('error on get scope tree',e);
// }
// }

// change by yg....


exports.calculateOneDayPayments=functions.runWith({timeoutSeconds:540, memory:'2GB'}).https.onRequest(async (req,res) => {
  
  console.log(`calculate 2 hr payments is calling`)  
  const now = new Date();
    console.log('now: '+now);
    
const startOfDay=new Date(now.getTime()-2*(60*60*1000));
    console.log('start of day(2 hr before): '+startOfDay);

    const checkPradhaanData=await admin.firestore().collection('pradhan_history').where('time', '>=',startOfDay).get();

    if(!checkPradhaanData.empty){
      return res.status(200).send({ message: `Calculation  already performed for ${startOfDay}`});
    }else{
      console.log('no pradhan history data here..................,',startOfDay)
    }
    
    const twoHrViews = await admin.firestore().collectionGroup('viewers').where('created_at', '>=', startOfDay).orderBy('created_at', 'asc').get();
 if (twoHrViews.empty) {
    return res.status(200).send({ message: `2 hr  has no earnings [${startOfDay}]` });
  }
  
  console.log('found 2 hr view , its not empty');
  const adsAndViewsMatrix = new Map();
  const uniqueAdIds = new Set();

  twoHrViews.docs.forEach((view, index) => {
    const { scope, ad_id } = view.data() || {};

    if (!adsAndViewsMatrix.has(scope)) {
      adsAndViewsMatrix.set(scope, new Map());
    }
    console.log('ads and views matrix: data fetched: ', adsAndViewsMatrix);

    if (!uniqueAdIds.has(ad_id)) {
      uniqueAdIds.add(ad_id);
    }
    console.log('uniqueAdIds get done: ', uniqueAdIds);
    const countMap = adsAndViewsMatrix.get(scope);
    countMap.set(ad_id, (countMap.get(ad_id) || 0) + 1);
    console.log('countmap finding done: ', countMap);
  });

  // Get ad details
  const allAdIds = [...uniqueAdIds];
  console.log("all ad Ids: ", allAdIds);
  const batchSize = 10;
  const batches = [];
  for (let i = 0; i < allAdIds.length; i += batchSize) {
    const batchIds = allAdIds.slice(i, i + batchSize);
    const batchQuery = admin.firestore().collection('ads').where('id', 'in', batchIds).get();
    batches.push(batchQuery);
  }

  const adSnapshots = await Promise.all(batches);
  const adDetails = adSnapshots.flatMap((snapshot) => snapshot.docs);

  // Calculate amount for each ad
  console.log('starting calculating  amount for each...');
  const scopeWithEarningMatrix = new Map();
  Array.from(adsAndViewsMatrix.entries()).forEach(([scopeId, viewCounts]) => {
    const totalScopeAmount = Array.from(viewCounts.entries()).map(([adId, count]) => {
      const adDetail = adDetails.find((detail) => detail.id === adId);
      if (!adDetail) {
        console.warn(`Ad not found for adId ${adId} in scope ${scopeId}`);
        return 0;
      }
      const { proposed_amount = 0, target_views = 1 } = adDetail.data();
      const amount = (count * proposed_amount) / target_views;
      return amount;
    }).reduce((a, b) => a + b, 0);
    scopeWithEarningMatrix.set(scopeId, totalScopeAmount);
  });
  console.log('finish calculating  amount for each ...');

  // Distribute amount to level and sub levels
  const allPradhaans = await admin.firestore().collection('pradhan').get();
  console.log("all pradhans fetching: ");
  const batch = admin.firestore().batch();

  // Map to aggregate amounts for each pradhanId
  const pradhanPayouts = new Map(); // Map<pradhanId, { totalAmount, scopes }>

  const tasks = Array.from(scopeWithEarningMatrix.entries()).map(async ([scopeId, totalAmount]) => {
    const pradhanData = allPradhaans.docs.find((pradhan) => pradhan.id === scopeId)?.data() || {};
    const tree = await getScopeTreeTwoHr(scopeId, pradhanData.level || 1, allPradhaans.docs);

    if (tree.size === 0) {
      console.log(`No pradhan or votes for scope ${scopeId}, skipping`);
      return [scopeId, new Map()];
    }

    // Validate totalAmount
    if (totalAmount <= 0) {
      console.warn(`Invalid totalAmount ${totalAmount} for scope ${scopeId}`);
      return [scopeId, new Map()];
    }

    // Calculate total votes
    const totalVotes = Array.from(tree.values()).reduce((sum, votes) => sum + votes, 0) || 1;
    if (totalVotes === 0) {
      console.warn(`No votes found for scope ${scopeId}`);
      return [scopeId, new Map()];
    }
    console.log("total votes: ", totalVotes);

    // Distribute amount based on votes ratio
    console.log("starting distribute amount based on votes.......");
    const distributedTree = new Map(
      Array.from(tree.entries()).map(([subScopeId, votes]) => {
        const distributedAmount = (votes / totalVotes) * totalAmount;
        return [subScopeId, distributedAmount];
      })
    );
    console.log("distribute amount based on votes ratio...finish");

    // Save Data in Firestore (Wallet + History)
    for (const [scope, amount] of distributedTree.entries()) {
      const pradhanDoc = allPradhaans.docs.find((pradhan) => pradhan.id === scope);
      const pradhanData = pradhanDoc?.data() || {};
      const pradhanId = pradhanData.pradhan_id || "admin";
      console.log("save data to firebase:.................");

      if (amount <= 0) {
        console.log("amount is <=0, process skip for it");
        continue;
      }

      const userSnapshot = await admin.firestore().collection('users').doc(pradhanId).get();
      const userData = userSnapshot.exists ? userSnapshot.data() : {};
      const bankSnapshot = await admin.firestore().collection('bankdetails').doc(pradhanId).get();
      const bankData = bankSnapshot.exists ? bankSnapshot.data() : {};

      // Aggregate amounts in pradhanPayouts Map
      if (!pradhanPayouts.has(pradhanId)) {
        pradhanPayouts.set(pradhanId, {
          totalAmount: 0,
          scopes: new Map(),
        });
      }

      const pradhanEntry = pradhanPayouts.get(pradhanId);
      pradhanEntry.totalAmount += Number(amount); // Add amount to total
      const currentScopeAmount = pradhanEntry.scopes.get(scope) || 0;
      pradhanEntry.scopes.set(scope, currentScopeAmount + Number(amount)); // Add amount to scope

      const walletRef = admin.firestore().collection('wallets').doc(pradhanId);
      batch.set(walletRef, {
        amount: FieldValue.increment(amount),
        used_amount: FieldValue.increment(amount),
      }, { merge: true });
      console.log('wallet updated: ...............');

      // Create Payout Entry
      const payoutRef = admin.firestore().collection('payouts').doc(`payout_${startOfDay.toISOString().split('T')[0]}`);
      const pradhaanPayoutRef = payoutRef.collection('pradhaan_payouts').doc(pradhanId);
      const pradhanLocData = pradhaanPayoutRef.collection('locations').doc(scope);

      console.log("pradhanTotalAmount: ", pradhanEntry.totalAmount, 'amount:', amount);

      const totalPayoutData = {
        user_id: pradhanId,
        pradhan_name: userData.name || 'Unknown',
        level: pradhanData.level || 1,
        full_address: userData.city ? [
          userData.postal?.name || '',
          userData.city?.name || '',
          userData.state?.name || '',
          userData.country?.name || ''
        ].filter(Boolean) : [],
        bank_details: {
          bank_name: bankData.bank_name || '',
          account_number: bankData.account_number || '',
          ifsc_number: bankData.ifsc_number || '',
          your_name: bankData.your_name || '',
          bank_address: bankData.bank_address || ''
        },
        total_amount: pradhanEntry.totalAmount, // Total amount for this pradhanId
        transaction_id: null,
        remark: null,
        status: 'pending',
        send_date: FieldValue.serverTimestamp(),
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      };

      batch.set(pradhaanPayoutRef, totalPayoutData, { merge: true });

      const payoutData = {
        user_id: pradhanId,
        pradhan_name: userData.name || 'Unknown',
        level: pradhanData.level || 1,
        full_address: userData.city ? [
          userData.postal?.name || '',
          userData.city?.name || '',
          userData.state?.name || '',
          userData.country?.name || ''
        ].filter(Boolean) : [],
        bank_details: {
          bank_name: bankData.bank_name || '',
          account_number: bankData.account_number || '',
          ifsc_number: bankData.ifsc_number || '',
          your_name: bankData.your_name || '',
          bank_address: bankData.bank_address || ''
        },
        amount_due: pradhanEntry.scopes.get(scope), // Total amount for this scope
        transaction_id: null,
        remark: null,
        status: 'pending',
        send_date: FieldValue.serverTimestamp(),
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        scope: scope,
      };

      batch.set(pradhanLocData, payoutData, { merge: true });

      console.log('payout created: .................',startOfDay);

      // Always Add History Record
      const historyRef = admin.firestore().collection('pradhan_history').doc();
      batch.set(historyRef, { pradhanId, scope: scopeId, amount, time: startOfDay });
    }

    return [scopeId, distributedTree];
  });

  const resultArray = await Promise.all(tasks);
  const result = new Map(resultArray);

  // Commit All Changes at Once
  await batch.commit();

  console.log("Final Result:", Object.fromEntries(result));

  // return res.status(200).send({ data: "total location revenue: "+ Array.from(scopeWithEarningMatrix.entries()), totalAds: allAdIds,message: `Amount sent to this location pradhans: `+JSON.stringify(Object.fromEntries(result)) });

function deepMapToObject(map) {
  const obj = {};
  for (const [key, value] of map.entries()) {
    if (value instanceof Map) {
      obj[key] = Object.fromEntries(value);
    } else {
      obj[key] = value;
    }
  }
  return obj;
}

const finalResult = deepMapToObject(result);

return res.status(200).send({
  data: "total location revenue: " + Array.from(scopeWithEarningMatrix.entries()),
  totalAds: allAdIds,
  message: "Amount sent to this location pradhans:",
  result: finalResult
});
});
///////////***********/////// */

// Old getScopeTreeTwoHr (using location collection)
async function getScopeTreeTwoHr(scopeId, level, allPradhans) {
  console.log(`getScopeTreeTwoHr called for scopeId: ${scopeId}, level: ${level}`);
  
  const levelMap = {
    3: 'State',
    2: 'city',
    1: 'postal'
  };

  const result = new Map();

  async function recurse(ref, currentLevel) {
    const id = ref.id;
    const pradhanDoc = allPradhans.find(p => p.id === id);
    if (pradhanDoc) {
      const votes = pradhanDoc.data()?.pradhan_model?.upvote_count || 0;
      result.set(id, votes);
    }

    if (currentLevel <= 1) return;

    const nextCollection = levelMap[currentLevel - 1];
    if (!nextCollection) return;

    const snapshot = await ref.collection(nextCollection).get();
    for (const doc of snapshot.docs) {
      await recurse(doc.ref, currentLevel - 1);
    }
  }

  let rootRef = admin.firestore().collection('location').doc('1-India');

  if (level >= 3) {
    const stateSnap = await rootRef.collection('State').doc(scopeId).get();
    if (!stateSnap.exists) return result;
    await recurse(stateSnap.ref, level);
  } else if (level === 2) {
    const statesSnap = await rootRef.collection('State').get();
    for (const state of statesSnap.docs) {
      const citySnap = await state.ref.collection('city').doc(scopeId).get();
      if (citySnap.exists) {
        await recurse(citySnap.ref, level);
        break;
      }
    }
  } else if (level === 1) {
    const statesSnap = await rootRef.collection('State').get();
    for (const state of statesSnap.docs) {
      const citiesSnap = await state.ref.collection('city').get();
      for (const city of citiesSnap.docs) {
        const postalSnap = await city.ref.collection('postal').doc(scopeId).get();
        if (postalSnap.exists) {
          await recurse(postalSnap.ref, level);
          break;
        }
      }
    }
  }

  console.log(`getScopeTree complete for ${scopeId}:`, Object.fromEntries(result));
  
  
  return result;
}

async function searchRefByBatch(group, fieldName, fieldValue) {
  const db = admin.firestore();
  let lastDoc = null;
  let hasMore = true;
  const batchSize = 15;

  while (hasMore) {
    let query = db.collectionGroup(group).limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    try {
      const snapshot = await query.get();
      if (snapshot.empty) {
        console.log('No more documents to fetch.');
        hasMore = false;
        break;
      }

      for (const data of snapshot.docs) {
        const dataRaw = data.data();
        if (dataRaw[fieldName] == fieldValue) {
          return { docs: [data] };
        }
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < batchSize) {
        hasMore = false;
      }
    } catch (error) {
      console.error("Error searching by batch:", error);
      hasMore = false;
    }
  }

  return undefined;
}


//TODO => if user at national level => compair weekly vote to the state level highest voted 2 user  stay at national level and remaning goes dowanward
//TODO :- if user at state Level => get top 2 user of state level an promote to nationnal level
//TODO :- if user at city level => get top 1 from city promote to state level
//TODO :- if user at postal level => get top 1 from ward promote to city level


/**
 * Helper: get top voted user from array
 */
function getTopUser(users) {
  if (!users || users.length === 0) return null;
  return users.reduce((prev, curr) =>
    curr.weekly_vote > prev.weekly_vote ? curr : prev
  );
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Update user level on every week
/*exports.sendToNextLevel = functions.runWith({ timeoutSeconds: 540, memory: '2GB' }).https.onRequest(async (req, res) => {
  try{
  const db = admin.firestore();
    const snapshot = await db.collection("users").get();
    const allUsers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    console.log('Reseting Weekly votes');

    //Reset weekly votes
      try {
        let batch = admin.firestore().batch();
        let counter = 0;

        for (const doc of snapshot.docs) {
          batch.update(doc.ref, { weekly_vote: 0 });
          counter++;

          if (counter === 500) {
            await batch.commit();
            console.log(`✅ Committed 500 docs`);
            batch = admin.firestore().batch();
            counter = 0;
          }
        }

        if (counter > 0) {
          await batch.commit();
          console.log(`✅ Committed remaining ${counter} docs`);
        }
      } catch (error) {
        console.error(error);
        return res.status(500).send({ error: error.message });
      }


    *//* ========== 1. Postal → City ========== *//*
    const postalGroups = {};
    allUsers.forEach(u => {
      if (u.level === 1) {
        if (!postalGroups[u.postal.id]) postalGroups[u.postal.id] = [];
        postalGroups[u.postal.id].push(u);
      }
    });

    for (const [postalId, users] of Object.entries(postalGroups)) {
      const topPostal = getTopUser(users);
      if (!topPostal) continue;

      const cityUser = allUsers.find(u =>
        u.level === 2 &&
        u.city.id === topPostal.city.id &&
        u.postal.id === postalId
      );


      if (cityUser) {
          // comparison
          if (topPostal.weekly_vote > cityUser.weekly_vote) {
            // promote postal → city
            console.log(
                        `🏆 Postal→City: ${topPostal.id} (votes: ${topPostal.weekly_vote}, from state: ${topPostal.state.id}, postal: ${topPostal.postal.id}) promoted, ` +
                        `${cityUser.id} (votes: ${cityUser.weekly_vote}, from state: ${cityUser.state.id}, city: ${cityUser.city.id}) demoted`
                      );
            await db.collection("users").doc(topPostal.id).update({ level: 2 });

            // downgrade city → postal
            await db.collection("users").doc(cityUser.id).update({ level: 1 });
          }
          else if(topPostal.weekly_vote === cityUser.weekly_vote) {
           console.log("Weekly_vote of both uses is same : no change");
          }else{
           console.log("city user Already stronger ")
          }
        }
        else {
          // if not city user  → direct promote
          await db.collection("users").doc(topPostal.id).update({ level: 2 });
      }
    }

    *//* ========== 2. City → State ========== *//*
    const cityGroups = {};
    allUsers.forEach(u => {
      if (u.level === 2) {
        if (!cityGroups[u.city.id]) cityGroups[u.city.id] = [];
        cityGroups[u.city.id].push(u);
      }
    });

    for (const [cityId, users] of Object.entries(cityGroups)) {
      const topCity = getTopUser(users);
      if (!topCity) continue;

      const stateUser = allUsers.find(u =>
        u.level === 3 &&
        u.state.id === topCity.state.id &&
        u.city.id === cityId
      );

      if (stateUser) {
              // comparison
              if (topCity.weekly_vote > stateUser.weekly_vote) {
                // promote postal → city
                console.log(
                            `🏆 City→State: ${topCity.id} (votes: ${topCity.weekly_vote}, from state: ${topCity.state.id}, city: ${topCity.city.id}) promoted, ` +
                            `${stateUser.id} (votes: ${stateUser.weekly_vote}, from state: ${stateUser.state.id}, city: ${stateUser.city.id}) demoted`
                          );
                await db.collection("users").doc(topCity.id).update({ level: 3 });

                // downgrade city → postal
                await db.collection("users").doc(stateUser.id).update({ level: 2 });
              }
              else if(topCity.weekly_vote === stateUser.weekly_vote){
              console.log("Weekly_vote of both use is same : no change");
            }else{
              console.log("state user Already stronger ")
              }
          }else {
             // if not city user  → direct promote
               await db.collection("users").doc(topCity.id).update({ level: 3 });
             }
    }

    *//* ========== 3. State → National ========== *//*

    const stateGroups = {};
      allUsers.forEach(u => {
        // group state level users
        if (u.level === 3) {
          if (!stateGroups[u.state.id]) stateGroups[u.state.id] = [];
          stateGroups[u.state.id].push(u);
        }
      });

      for (const [stateId, users] of Object.entries(stateGroups)) {
        // top 2 state users
        const topStateUsers = users
          .sort((a, b) => b.weekly_vote - a.weekly_vote)
          .slice(0, 2);

        // get top 2 National users that belong to that state
        const nationalUsers = allUsers
          .filter(u => u.level === 4 && u.state.id === stateId)
          .sort((a, b) => b.weekly_vote - a.weekly_vote)
          .slice(0, 2);

        // make a  pool for state and national level
        const pool = [...topStateUsers, ...nationalUsers];
        if (pool.length === 0) continue;

        // final TOP2 user of state (if they are state or national level)
        const finalTop2 = pool.sort((a, b) => b.weekly_vote - a.weekly_vote).slice(0, 2);

        for (const u of pool) {
          const newLevel = finalTop2.some(t => t.id === u.id) ? 4 : 3;

          if (u.level !== newLevel) {
            // level change hua
              if (newLevel === 4) {
                await db.collection("users").doc(u.id).update({ level: newLevel });
              } else {
                await db.collection("users").doc(u.id).update({ level: newLevel });
              }

          } else {
            // If no changes in user level
            if (newLevel === 4) {
              console.log(`✅ Still National: ${u.id} (votes: ${u.weekly_vote}, from state: ${u.state.id}) remains National`);
            } else {
              console.log(`ℹ️ Still State: ${u.id} (votes: ${u.weekly_vote}, from state: ${u.state.id}) remains State`);
            }
          }
        }
      }
    console.log("✅ Promotion cycle completed.");
    return null;
  }catch(e){
  console.log('Level Promotion faild');
  }
});*/
exports.sendToNextLevel = functions
  .runWith({ timeoutSeconds: 540, memory: "2GB" })
  .https.onRequest(async (req, res) => {
    try {
      const db = admin.firestore();
      const snapshot = await db.collection("users").get();
      let allUsers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      console.log("🚀 Resetting weekly votes...");

      // ================= Reset weekly votes =================
      try {
        let batch = db.batch();
        let counter = 0;

        for (const doc of snapshot.docs) {
          batch.update(doc.ref, { weekly_vote: 0 });
          counter++;

          if (counter === 500) {
            await batch.commit();
            console.log(`✅ Committed 500 docs`);
            batch = db.batch();
            counter = 0;
          }
        }

        if (counter > 0) {
          await batch.commit();
          console.log(`✅ Committed remaining ${counter} docs`);
        }
      } catch (error) {
        console.error("❌ Error resetting votes:", error);
        return res.status(500).send({ error: error.message });
      }

      // ================= 1. Postal → City =================
      const postalGroups = {};
      allUsers.forEach(u => {
        if (u.level === 1 && u.postal?.id && u.city?.id && u.state?.id) {
          if (!postalGroups[u.postal.id]) postalGroups[u.postal.id] = [];
          postalGroups[u.postal.id].push(u);
        }
      });

      for (const [postalId, users] of Object.entries(postalGroups)) {
        const topPostal = getTopUser(users);
        if (!topPostal) continue;

        const cityUser = allUsers.find(
          u =>
            u.level === 2 &&
            u.city?.id === topPostal.city.id &&
            u.postal?.id === postalId
        );

        const batch = db.batch();

        if (cityUser) {
          if (topPostal.weekly_vote > cityUser.weekly_vote) {
            const userRef = db.collection("users").doc(cityUser.id);
            console.log(`🏆 Postal→City: ${topPostal.id} promoted, ${cityUser.id} demoted`);

            batch.update(db.collection("users").doc(topPostal.id), { level: 2 });
            batch.update(userRef, { level: 1 });

            if (
              cityUser.hasOwnProperty("preferred_election_location") &&
              cityUser.preferred_election_location !== null &&
              cityUser.preferred_election_location !== "" &&
              !(typeof cityUser.preferred_election_location === "object" &&
                Object.keys(cityUser.preferred_election_location).length === 0)
            ) {
              batch.update(userRef, {
                preferred_election_location: {
                  id: cityUser.postal?.id ?? '',
                  name: cityUser.postal?.name ?? '',
                  text: cityUser.postal?.text ?? ''
                }
              });
            } else {
              console.log(`Skipping user ${cityUser.id} — preferred_election_location missing/null/empty`);
            }
          } else if (topPostal.weekly_vote === cityUser.weekly_vote) {
            console.log("⚖️ Postal vs City tie → no change");
          } else {
            console.log("➡️ City user stronger → no change");
          }
        } else {
          console.log(`⬆️ Promoting postal ${topPostal.id} to city`);
          batch.update(db.collection("users").doc(topPostal.id), { level: 2 });
        }

        await batch.commit();
      }

      // ================= 2. City → State =================
      const cityGroups = {};
      allUsers.forEach(u => {
        if (u.level === 2 && u.city?.id && u.state?.id) {
          if (!cityGroups[u.city.id]) cityGroups[u.city.id] = [];
          cityGroups[u.city.id].push(u);
        }
      });

      for (const [cityId, users] of Object.entries(cityGroups)) {
        const topCity = getTopUser(users);
        if (!topCity) continue;

        const stateUser = allUsers.find(
          u =>
            u.level === 3 &&
            u.state?.id === topCity.state.id &&
            u.city?.id === cityId
        );

        const batch = db.batch();

        if (stateUser) {
          if (topCity.weekly_vote > stateUser.weekly_vote) {
           const userRef = db.collection("users").doc(stateUser.id);
            console.log(`🏆 City→State: ${topCity.id} promoted, ${stateUser.id} demoted`);
            batch.update(db.collection("users").doc(topCity.id), { level: 3 });
            batch.update(db.collection("users").doc(stateUser.id), { level: 2 });
            if (
                                        stateUser.hasOwnProperty("preferred_election_location") && // field exists
                                        stateUser.preferred_election_location !== null && // not null
                                        stateUser.preferred_election_location !== "" && // not empty string
                                        !(typeof stateUser.preferred_election_location === "object" && Object.keys(stateUser.preferred_election_location).length === 0) // not empty object
                                      ) {
                                        batch.update(userRef, {
                                          preferred_election_location: {
                                            id: stateUser.city.id ?? '',
                                            name: stateUser.city.name ?? '',
                                            text: stateUser.city.text ?? ''
                                          }
                                        });
                                      } else {
                                        // Skip or only update level if needed
                                        console.log(`Skipping user ${stateUser.id} — preferred_election_location missing/null/empty`);
                                      }

          } else if (topCity.weekly_vote === stateUser.weekly_vote) {
            console.log("⚖️ City vs State tie → no change");
          } else {
            console.log("➡️ State user stronger → no change");
          }
        } else {
          console.log(`⬆️ Promoting city ${topCity.id} to state`);
          batch.update(db.collection("users").doc(topCity.id), { level: 3 });
        }

        await batch.commit();
      }

      // ================= 3. State → National =================
      const stateGroups = {};
      allUsers.forEach(u => {
        if (u.level === 3 && u.state?.id) {
          if (!stateGroups[u.state.id]) stateGroups[u.state.id] = [];
          stateGroups[u.state.id].push(u);
        }
      });

      for (const [stateId, users] of Object.entries(stateGroups)) {
        const topStateUsers = users.sort((a, b) => b.weekly_vote - a.weekly_vote).slice(0, 2);

        const nationalUsers = allUsers
          .filter(u => u.level === 4 && u.state?.id === stateId)
          .sort((a, b) => b.weekly_vote - a.weekly_vote)
          .slice(0, 2);

        const pool = [...topStateUsers, ...nationalUsers];
        if (pool.length === 0) continue;

        const finalTop2 = pool.sort((a, b) => b.weekly_vote - a.weekly_vote).slice(0, 2);
        const winnerSet = new Set(finalTop2.map(u => u.id));

        const batch = db.batch();

        for (const u of pool) {
        const userRef = db.collection("users").doc(u.id);
          const newLevel = winnerSet.has(u.id) ? 4 : 3;
          if (u.level !== newLevel) {
            batch.update(db.collection("users").doc(u.id), { level: newLevel });
            console.log(
              `${newLevel === 4 ? "⬆️ Promoted to National" : "⬇️ Demoted to State"}: ${u.id}`
            );
            if(newLevel === 3 && u.level === 4){

            if (u.hasOwnProperty("preferred_election_location") && // field exists
                u.preferred_election_location !== null && // not null
                u.preferred_election_location !== "" && // not empty string
                !(typeof u.preferred_election_location === "object" && Object.keys(u.preferred_election_location).length === 0) // not empty object
                ) {
                   batch.update(userRef, {
                   preferred_election_location: {
                     id: u.state.id ?? '',
                     name: u.state.name ?? '',
                     text: u.state.text ?? ''
                   }
                });
                }else {
                  // Skip or only update level if needed
                  console.log(`Skipping user ${u.id} — preferred_election_location missing/null/empty`);
                }
          } else {
            console.log(
              `${newLevel === 4 ? "✅ Still National" : "ℹ️ Still State"}: ${u.id}`
            );
          }
        }


       }
       }
      console.log("✅ Promotion cycle completed.");
      res.send("Promotion cycle completed.");
    } catch (e) {
      console.error("❌ Level Promotion failed:", e);
      res.status(500).send("Level Promotion failed.");
    }
  });

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
async function  migrateUserLevelsOnce(allUsers) {
  let changes = 0;
  const db = admin.firestore();

  console.log("**************************************************************************************");

  // Helper: safe group by key
  function safeGroupBy(users, keyFn) {
    return users.reduce((groups, u) => {
      const key = keyFn(u);
      if (!key) return groups;
      if (!groups[key]) groups[key] = [];
      groups[key].push(u);
      return groups;
    }, {});
  }

  // Helper: commit batch safely (splits if >500 ops)
  async function safeCommit(ops) {
    for (let i = 0; i < ops.length; i += 500) {
      const slice = ops.slice(i, i + 500);
      const batch = db.batch();
      slice.forEach(op => batch.update(db.collection("users").doc(op.id), { level: op.level }));
      await batch.commit();
    }
  }

  /* ===== 1. Postal → City ===== */
  const postalGroups = safeGroupBy(allUsers.filter(u => u.level === 1), u => u?.postal?.id);

  for (const [postalId, users] of Object.entries(postalGroups)) {
    const topPostal = getTopUser(users);
    if (!topPostal) continue;

    const cityUsers = allUsers.filter(u => u.level === 2 && u?.postal?.id === postalId);
    console.log(`${cityUsers.length} city users found for postal ${postalId}`);

    const pool = cityUsers.length ? [topPostal, ...cityUsers] : [topPostal];
    const finalTop1 = pool.sort((a, b) => b.weekly_vote - a.weekly_vote)[0];

    const ops = [];
    for (const u of pool) {
      const newLevel = (u.id === finalTop1.id) ? 2 : 1;
      if (u.level !== newLevel) {
        ops.push({ id: u.id, level: newLevel });
        allUsers = allUsers.map(user => user.id === u.id ? { ...user, level: newLevel } : user);
        changes++;
      }
    }
    if (ops.length) await safeCommit(ops);
  }

  /* ===== 2. City → State ===== */
  const cityGroups = safeGroupBy(allUsers.filter(u => u.level === 2), u => u?.city?.id);

  for (const [cityId, users] of Object.entries(cityGroups)) {
    const topCity = getTopUser(users);
    if (!topCity) continue;

    const stateUsers = allUsers.filter(u =>
      u.level === 3 && u?.state?.id === topCity?.state?.id && u?.city?.id === cityId
    );

    console.log(`${stateUsers.length} state users found for city ${cityId}`);

    const pool = stateUsers.length ? [topCity, ...stateUsers] : [topCity];
    const finalTop1 = pool.sort((a, b) => b.weekly_vote - a.weekly_vote)[0];

    const ops = [];
    for (const u of pool) {
      const newLevel = (u.id === finalTop1.id) ? 3 : 2;
      if (u.level !== newLevel) {
        ops.push({ id: u.id, level: newLevel });
        allUsers = allUsers.map(user => user.id === u.id ? { ...user, level: newLevel } : user);
        changes++;
      }
    }
    if (ops.length) await safeCommit(ops);
  }

  /* ===== 3. State → National ===== */
  const stateGroups = safeGroupBy(allUsers.filter(u => u.level === 3), u => u?.state?.id);

  for (const [stateId, users] of Object.entries(stateGroups)) {
    const topStateUsers = users.sort((a, b) => b.weekly_vote - a.weekly_vote).slice(0, 2);
    if (topStateUsers.length === 0) continue;

    const nationalUsers = allUsers.filter(u => u.level === 4 && u?.state?.id === stateId);
    const pool = [...topStateUsers, ...nationalUsers];

    const winners = pool
      .sort((a, b) => b.weekly_vote - a.weekly_vote || b.level - a.level)
      .slice(0, 2);

    const winnerSet = new Set(winners.map(u => u.id));

    const ops = [];
    for (const u of pool) {
      const newLevel = winnerSet.has(u.id) ? 4 : 3;
      if (u.level !== newLevel) {
        ops.push({ id: u.id, level: newLevel });
        allUsers = allUsers.map(user => user.id === u.id ? { ...user, level: newLevel } : user);
        changes++;
      } else {
        console.log(`${newLevel === 4 ? "✅ Still National" : "ℹ️ Still State"}: ${u.id} (votes: ${u.weekly_vote}, state: ${u?.state?.id})`);
      }
    }
    if (ops.length) await safeCommit(ops);
  }

  return { changes, allUsers };
}



/**
 * Auto-loop until no changes occur
 */
exports.migrateUserlevel = functions
  .runWith({ timeoutSeconds: 540, memory: '2GB' })
  .https.onRequest(async (req, res) => {
    try {
      console.log("🚀 Starting auto-loop migration...");
      let snapshot = await admin.firestore().collection("users").get();
      let allUsers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      let iteration = 0;
      let changes = 1;

      while (changes > 0 && iteration < 5) {
        iteration++;
        console.log(`\n🔄 Migration run #${iteration}`);
        const result = await migrateUserLevelsOnce(allUsers);
        changes = result.changes;
        allUsers = result.allUsers;
        console.log(`Changes in this run: ${changes}`);
      }

      console.log("✅ All users settled in their deserved levels!");
      res.send("Migration completed successfully!");
    } catch (err) {
      console.error("❌ Failed to reset levels", err);
      res.status(500).send("Migration failed.");
    }
  });

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//async function migrateUserLevelsOnce(allUsers) {
//  let changes = 0;
//
//  /** ===== 1. Postal → City ===== */
//  const postalGroups = {};
//  allUsers.forEach(u => {
//    if (u.level === 1) {
//      if (!postalGroups[u.postalID]) postalGroups[u.postalID] = [];
//      postalGroups[u.postalID].push(u);
//    }
//  });
//
//  for (const [postalId, users] of Object.entries(postalGroups)) {
//    const topPostal = getTopUser(users);
//    if (!topPostal) continue;
//
//    // Get all City level users for this postal
//    const cityUsers = allUsers.filter(u => u.level === 2 && u.postalID === postalId);
//    console.log(`${cityUsers.length} city users found for postal ${postalId}`);
//
//    if (cityUsers.length === 0) {
//      if (topPostal.level !== 2) {
//        topPostal.level = 2;
//        changes++;
//      }
//      continue;
//    }
//
//    const cityAndPostalPool = [topPostal, ...cityUsers];
//    const finalTop1CityUser = cityAndPostalPool.sort((a, b) => b.weekly_vote - a.weekly_vote)[0];
//
//    for (const u of cityAndPostalPool) {
//      const newLevel = (u.id === finalTop1CityUser.id) ? 2 : 1;
//      if (u.level !== newLevel) {
//        u.level = newLevel;
//        changes++;
//      }
//    }
//  }
//
//  /** ===== 2. City → State ===== */
//  const cityGroups = {};
//  allUsers.forEach(u => {
//    if (u.level === 2) {
//      if (!cityGroups[u.cityID]) cityGroups[u.cityID] = [];
//      cityGroups[u.cityID].push(u);
//    }
//  });
//
//  for (const [cityId, users] of Object.entries(cityGroups)) {
//    const topCity = getTopUser(users);
//    if (!topCity) continue;
//
//    const stateUsers = allUsers.filter(u =>
//      u.level === 3 && u.stateID === topCity.stateID && u.cityID === cityId
//    );
//    console.log(`${stateUsers.length} state users found for city ${cityId}`);
//
//    if (stateUsers.length === 0) {
//      if (topCity.level !== 3) {
//        topCity.level = 3;
//        changes++;
//      }
//      continue;
//    }
//
//    const stateAndCityPool = [topCity, ...stateUsers];
//    const finalTop1StateUser = stateAndCityPool.sort((a, b) => b.weekly_vote - a.weekly_vote)[0];
//
//    for (const u of stateAndCityPool) {
//      const newLevel = (u.id === finalTop1StateUser.id) ? 3 : 2;
//      if (u.level !== newLevel) {
//        u.level = newLevel;
//        changes++;
//      }
//    }
//  }
//
//  /** ===== 3. State → National ===== */
//  const stateGroups = {};
//  allUsers.forEach(u => {
//    if (u.level === 3) {
//      if (!stateGroups[u.stateID]) stateGroups[u.stateID] = [];
//      stateGroups[u.stateID].push(u);
//    }
//  });
//
//  for (const [stateId, users] of Object.entries(stateGroups)) {
//    const topStateUsers = users.sort((a, b) => b.weekly_vote - a.weekly_vote).slice(0, 2);
//    if (topStateUsers.length === 0) continue;
//    console.log(
//      `Top State Users for ${stateId}:`,
//      topStateUsers.map(u => ({ id: u.id, votes: u.weekly_vote }))
//    );
//
//    const nationalUsers = allUsers.filter(u => u.level === 4 && u.stateID === stateId);
//
//    if (nationalUsers.length === 0) {
//      for (const sUser of topStateUsers) {
//        if (sUser.level !== 4) {
//          sUser.level = 4;
//          changes++;
//          console.log(`Promoted State ${sUser.id} → National`);
//        }
//      }
//      continue;
//    }
//    const stateNationPool = [...topStateUsers, ...nationalUsers];
//    const winners = stateNationPool
//      .sort((a, b) =>
//        b.weekly_vote - a.weekly_vote ||  // pehle votes
//        b.level - a.level                 // tie me prefer level 4
//      )
//      .slice(0, 2);
//
//    const winnerSet = new Set(winners.map(u => u.id));
//
//    for (const u of stateNationPool) {
//      const newLevel = winnerSet.has(u.id) ? 4 : 3;
//      if (u.level !== newLevel) {
//        u.level = newLevel;
//        changes++;
//        console.log(`${newLevel === 4 ? "Promoted" : "Demoted"} ${u.id} → ${newLevel === 4 ? "National" : "State"} (state ${stateId})`);
//      }
//    }
//
//  }
//
//  return { changes, allUsers };
//}
//
///**
// * Auto-loop until no changes occur
// */
//exports.migrateUserlevel = functions.https.onRequest(async (req, res) => {
//  console.log("🚀 Starting auto-loop migration...");
// //let snapshot = await db.collection("users").get();
//  //let allUsers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
//
//  let iteration = 0;
//  let changes = 1;
//
//  while (changes > 0 && iteration < 5) { // max 4 runs as discussed
//    iteration++;
//    console.log(`\n🔄 Migration run #${iteration}`);
//    const result = await migrateUserLevelsOnce(allUsers);
//    changes = result.changes;
//    allUsers = result.allUsers;
//    console.log(`Changes in this run: ${changes}`);
//  }
//
//  console.log("✅ All users settled in their deserved levels!");
//
//});


/*exports.sendToNextLevel = functions.https.onRequest(async (req, res) => {
  try {
    // Sends 10 users to the next level every week
    const sachivCollection = admin.firestore().collection('sachiv');
    const userCollection = admin.firestore().collection('users');

    const sachivDocs = await sachivCollection.get(); // Fetch all sachiv documents

    const updatePromises = sachivDocs.docs.map(async (sachivDoc) => {
      const sachivData = sachivDoc.data();
      const sachivAreaLevel = sachivData.level;
      const sachivAreaText = sachivData.locationText;
      console.log("sachivAreaLevel: " + sachivAreaLevel + ", sachivAreaText: " + sachivAreaText);

      var locQuery = "postal.text";
      switch (sachivAreaLevel) {
        case 1:
          locQuery = "postal.text";
          break;
        case 2:
          locQuery = "city.text";
          break;
        case 3:
          locQuery = "state.text";
          break;
        case 4:
          locQuery = "country.text";
          break;
        default:
          locQuery = "postal.text";
          break;
      }

      console.log("locQuery: " + locQuery);
      if (sachivAreaLevel < 4) {

        // Query for users with the highest votes and matching location
        const highestVoteUserQuery = userCollection
          .where(locQuery, "==", sachivAreaText)
          .where("level", "==", sachivAreaLevel)
          .where("updated_this_week", "==", false)
          .orderBy("upvote_count", "desc")
          .limit(10);

        const highestVoteUserSnapshot = await highestVoteUserQuery.get();
        console.log("Highest User For " + sachivData.locationText + ": " + highestVoteUserSnapshot.docs.length);

        if (!highestVoteUserSnapshot.empty) {
          const batch = admin.firestore().batch(); // Create a new batch

          highestVoteUserSnapshot.forEach(async (userSnap) => {
            const updateRef = userCollection.doc(userSnap.id);
            const user = userSnap.data();
            if (!user.oadmin) {

              // Get the FCM token from the user's data
              const userFCMToken = user.fcmToken;

              if (userFCMToken) {
                // Send a notification when the user's level is upgraded
                const message = {
                  notification: {
                    title: 'Level Upgrade',
                    body: `Congratulations! Your level has been upgraded to ${sachivAreaLevel + 1}`,
                  },
                  token: userFCMToken,
                };

                // Send the notification
                try {
                  await admin.messaging().send(message);
                  console.log(`Notification sent to user ${userSnap.id}`);
                } catch (error) {
                  console.error('Error sending notification:', error);
                }
              }

              batch.update(updateRef, {
                "level": sachivAreaLevel + 1,
                "updated_this_week": true,
              });

              console.log(`User ${userSnap.id} is promoted to ${sachivAreaLevel + 1} level`);
            }
          });

          return batch.commit(); // Return a promise for this batch update
        } else {
          console.log(`No qualifying user found for Update To next level: ${sachivData.locationText}`);

          return Promise.resolve(); // Return a resolved promise if there are no qualifying users
        }
      } else {
        console.log(`On Highest level: ${sachivData.locationText}`);
        return Promise.resolve(); // Return a resolved promise if there are no qualifying users

      }
    });

    // Wait for all batch updates to complete
    await Promise.all(updatePromises);

    res.status(200).send('User Updated level-wise');
  } catch (error) {
    console.error('User Updated level-wise:', error);
    res.status(500).send(`Error User Updated level-wise: ${error.message}`);
  }
  });*/

exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    // Extract the device token from the query parameters
    const registrationToken = req.query.deviceToken;

    if (!registrationToken) {
      res.status(400).send('Device token is missing in the URL parameters');
      return;
    }

    const message = {
      notification: {
        title: 'Notification Title',
        body: 'Notification Body',
      },
      token: registrationToken,
    };

    // Send the message
    const response = await admin.messaging().send(message);

    console.log('Notification sent successfully:', response);
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});

exports.resetUserData = functions.https.onRequest(async (req, res) => {
  try {
    const userCollection = admin.firestore().collection('users');

    // Query all user documents
    const usersSnapshot = await userCollection.get();

    const batch = admin.firestore().batch();

    usersSnapshot.forEach(async (userDoc) => {
      const userRef = userCollection.doc(userDoc.id);

      // Update the 'todays_upvote' field to 0
      batch.update(userRef, { todays_upvote: 0, level: 1, oneday_vote: 0, upvote_count: 0 });

      // Check if an 'upvote' subcollection exists and delete it
      const upvoteCollectionRef = userRef.collection('upvote');
      const upvoteDocsSnapshot = await upvoteCollectionRef.get();

      if (!upvoteDocsSnapshot.empty) {
        upvoteDocsSnapshot.forEach((upvoteDoc) => {
          batch.delete(upvoteCollectionRef.doc(upvoteDoc.id));
        });
      }
    });

    // Commit the batch update
    await batch.commit();

    res.status(200).send('todays_upvote reset for all users, and upvote subcollections deleted');
  } catch (error) {
    console.error('Error resetting todays_upvote:', error);
    res.status(500).send('Error resetting todays_upvote');
  }
});

// Cloud Function to update 'updated_this_week' to false for all documents in the user collection
exports.updatedThisWeek = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();
  const userCollection = db.collection('users');

  try {
    // Get all documents in the user collection
    const snapshot = await userCollection.get();

    // Update 'updated_this_week' to false for each document
    const updatePromises = [];
    snapshot.forEach(doc => {
      const updatePromise = doc.ref.update({
        updated_this_week: false
      });
      updatePromises.push(updatePromise);
    });

    // Wait for all updates to complete
    await Promise.all(updatePromises);

    console.log('Update completed successfully.');
    res.status(200).send('Update completed successfully.');
  } catch (error) {
    console.error('Error updating documents:', error);
    res.status(500).send('Error updating documents');
  }
});

// function for deleting a document recursively
exports.deleteDocumentRecursively = functions.https.onCall(async (data, context) => {
  // grabbing the document reference from the data
  const docPath = data.documentPath

  // grabbing the document reference
  const docReference = admin.firestore().doc(docPath)

  // deleting the document recursively
  try {
    await admin.firestore().recursiveDelete(docReference)
  } catch (e) {
    console.error(e)
    throw new HttpsError('internal', 'Deletion was not successful. Please try again later.')
  }
})
