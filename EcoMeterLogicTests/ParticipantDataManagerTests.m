//
//  ParticipantDataManagerTests.m
//  uni-project
//
//  Created by Pavel Ermolin on 04.02.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "ParticipantDataManagerTests.h"
#import "ParticipantDataManager.h"
#import "ParticipantDataManager-Private.h"
#import "OCMock.h"

static const int TESTID = 3;

@interface ParticipantDataManagerTests ()

@property (nonatomic, strong) ParticipantDataManager *manager;

@end

@implementation ParticipantDataManagerTests


- (void)setUp{
    
    [super setUp];
    
    self.manager = [[ParticipantDataManager alloc] initWithParticipantId:TESTID];
    
    // Set-up code here.
    
}

-(void)testInitCallsHelpers {
    id mock = [OCMockObject partialMockForObject:self.manager];
    [[mock expect] initScalarAttributes];
    [mock init];
    [mock verify];
}

-(void)testObjectHasCorrectId {
    STAssertEquals(TESTID, self.manager.currentParticipantId,@"We expected %i as ID, but it was %i",TESTID,self.manager.currentParticipantId);
}

- (void)tearDown{
    
    // Tear-down code here.
    
    [super tearDown];
    
}

@end
