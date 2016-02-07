//
//  TidasErrors.h
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 9/23/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#ifndef TidasErrors_h
#define TidasErrors_h

enum tidasErrors {
  errTidasSuccess   = 0,  // Success
  errNoTouchID      = 1,  // TouchID not instantiated
  errBadData        = 2,  // Bad data provided to sign and box request
  errUserCancelled  = 3,  // Tidas keying data missing
  errNotAuthorized  = 4   // User failed TouchID auth
};

#endif
