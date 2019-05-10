//
//  Constants.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/13/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

public var recentBadgeHandler: ListenerRegistration?
let userDefaults = UserDefaults.standard

//NOTIFICATIONS
public let USER_DID_LOGIN_NOTIFICATION = NSNotification.Name("UserDidLoginNotification")
public let APP_STARTED_NOTIFICATION = NSNotification.Name("AppStartedNotification")

//SB IDs
public let FINAL_FORM_VC = "finalRegisterFormVC"
public let MAIN_APPLICATION_ID = "mainApplication"
public let WELCOME_VC = "welcomeScreenVC"
public let USER_CONTACTS_VC = "userContactsVC"
public let USER_PROFILE_VC = "userProfileVC"
public let CHAT_VC = "chatDetailVC"
public let MAP_VC = "mapVC"
public let PICTURE_VC = "picturesVC"
public let CONTACTS_VC = "contactsVC"
public let CREATE_NEW_GROUP_VC = "createNewGroupVC"

//CELL REUSE IDs
public let USER_CONTACT_CELL = "userContactCell"
public let RECENT_CHAT_CELL = "recentChatCell"
public let PICTURE_CELL = "pictureCell"
public let BLOCKED_USER_CELL = "blockedUserCell"
public let BACKGROUND_CELL = "backgroundCell"
public let GROUP_MEMBER_CELL = "groupMemberCell"

//IDS and Keys
public let kFILEREFERENCE = "gs://freespeaker-1c889.appspot.com"
public let kONESIGNALAPPID = ""
public let kSINCHKEY = ""
public let kSINCHSECRET = ""
public let kAPPURL = ""



//Firebase Headers
public let kUSER_PATH = "User"
public let kTYPINGPATH_PATH = "Typing"
public let kRECENT_PATH = "Recent"
public let kMESSAGE_PATH = "Message"
public let kGROUP_PATH = "Group"
public let kCALL_PATH = "Call"

//FUser
public let kOBJECTID = "objectId"
public let kCREATEDAT = "createdAt"
public let kUPDATEDAT = "updatedAt"
public let kEMAIL = "email"
public let kPHONE = "phone"
public let kCOUNTRYCODE = "countryCode"
public let kFACEBOOK = "facebook"
public let kLOGINMETHOD = "loginMethod"
public let kPUSHID = "pushId"
public let kFIRSTNAME = "firstname"
public let kLASTNAME = "lastname"
public let kFULLNAME = "fullname"
public let kAVATAR = "avatar"
public let kCURRENTUSER = "currentUser"
public let kISONLINE = "isOnline"
public let kVERIFICATIONCODE = "firebase_verification"
public let kCITY = "city"
public let kCOUNTRY = "country"
public let kBLOCKEDUSERID = "blockedUserId"



//
public let kBACKGROUNDIMAGE = "backgroundImage"
public let kSHOWAVATAR = "showAvatar"
public let kPASSWORDPROTECT = "passwordProtect"
public let kFIRSTRUN = "firstRun"
public let kNUMBEROFMESSAGES = 10
public let kMAXDURATION = 120.0
public let kAUDIOMAXDURATION = 120.0
public let kSUCCESS = 2

//recent
public let kCHATROOMID = "chatRoomID"
public let kUSERID = "userId"
public let kDATE = "date"
public let kPRIVATE = "private"
public let kGROUP = "group"
public let kGROUPID = "groupId"
public let kRECENTID = "recentId"
public let kMEMBERS = "members"
public let kMESSAGE = "message"
public let kMEMBERSTOPUSH = "membersToPush"
public let kDISCRIPTION = "discription"
public let kLASTMESSAGE = "lastMessage"
public let kCOUNTER = "counter"
public let kTYPE = "type"
public let kWITHUSERUSERNAME = "withUserUserName"
public let kWITHUSERUSERID = "withUserUserID"
public let kOWNERID = "ownerID"
public let kSTATUS = "status"
public let kMESSAGEID = "messageId"
public let kNAME = "name"
public let kSENDERID = "senderId"
public let kSENDERNAME = "senderName"
public let kTHUMBNAIL = "thumbnail"
public let kISDELETED = "isDeleted"

//Contacts
public let kCONTACT = "contact"
public let kCONTACTID = "contactId"

//message types
public let kPICTURE = "picture"
public let kTEXT = "text"
public let kVIDEO = "video"
public let kAUDIO = "audio"
public let kLOCATION = "location"

//coordinates
public let kLATITUDE = "latitude"
public let kLONGITUDE = "longitude"


//message status
public let kDELIVERED = "delivered"
public let kREAD = "read"
public let kREADDATE = "readDate"
public let kDELETED = "deleted"



//push
public let kDEVICEID = "deviceId"



//Call
public let kISINCOMING = "isIncoming"
public let kCALLERID = "callerId"
public let kCALLERFULLNAME = "callerFullName"
public let kCALLSTATUS = "callStatus"
public let kWITHUSERFULLNAME = "withUserFullName"
public let kCALLERAVATAR = "callerAvatar"
public let kWITHUSERAVATAR = "withUserAvatar"
