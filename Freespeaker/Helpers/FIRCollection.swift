//
//  FCollection.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/16/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FIRCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FIRCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}
