

#import "Constants.h"

@implementation Constants

NSString *  const CPDThemeNameDarkGradient  = @"Dark Gradient";
NSString *  const CPDThemeNamePlainBlack    = @"Plain Black";
NSString *  const CPDThemeNamePlainWhite    = @"Plain White";
NSString *  const CPDThemeNameSlate         = @"Slate";
NSString *  const CPDThemeNameStocks        = @"Stocks";

NSString *  const CPDTickerSymbolAAPL       = @"AAPL";
NSString *  const CPDTickerSymbolGOOG       = @"GOOG";
NSString *  const CPDTickerSymbolMSFT       = @"MSFT";

NSString *  const pieChart                  = @"Pie Chart";
NSString *  const barGraph                  = @"Bar Graph";
NSString *  const scatterPlot               = @"Scatter Plot";

// IMPORTANT! Get Requests must look like: ..hcm-lab.de/downloads/buehling/adaptiveart/CurrentCostTreeOnline/rpctest.php?userID=3&action=get&...
// If the server-path changed/doesnt exist anymore, the System-Parts that rely on this would break/not function as expected.
// See EnergyClockDataManager-Class and ParticipantDataManager-Class for more Info.
NSString *  const currentCostServerBaseURLString = @"http://www.hcm-lab.de/downloads/buehling/adaptiveart/CurrentCostTreeOnline/";
NSString *  const currentCostServerBaseURLHome   = @"www.hcm-lab.de";
float       const OfficeArea     = 20.0f;
float       const AvgOfficeEnergyConsumption = 55.0f;
NSInteger   const MySensorID     = 3;
NSInteger   const FirstSensorID  = 3;
NSInteger   const SecondSensorID = 4;
NSInteger   const ThirdSensorID  = 5;

// Energy-Label: levels/ranks
NSInteger   const APlusPlusPlus  = 1;
NSInteger   const APlusPlus      = 2;
NSInteger   const APlus          = 3;
NSInteger   const A              = 4;
NSInteger   const B              = 5;
NSInteger   const C              = 6;
NSInteger   const D              = 7;

NSString * const ScoreWasCalculated      = @"ScoreWasCalculated";
NSString * const RankWasCalculated       = @"RankWasCalculated";

NSString * const DayChartsMode           = @"DayChartsMode";
NSString * const MultiLevelPieChartMode  = @"MultiLevelPieChartMode";

// test data flag, set to NO when not in dev mode
BOOL const USEDUMMYDATA                 = NO;

// Wunderground Weather API, projectname: ecometerapp
// prefix: WWA
// http://api.wunderground.com/api/Your_Key/astronomy/q/Your_Country/Your_City.json
// http://api.wunderground.com/api/Your_Key/history_YYYYMMDD/q/CA/San_Francisco.json
NSString * const WWAKey     = @"7a5424a084a5ba90";
NSString * const WWABaseURL    = @"http://api.wunderground.com/api/";
NSString * const WWAAstronomyURLpart = @"/astronomy/";
NSString * const WWALocationURLpart = @"q/Germany/Augsburg.json";
NSString * const WWAHistoryURLpart = @"/history_"; // '/history_YYYYMMDD/'

NSString * const EnergyClockDataSaved    = @"AggregatedDaysSaved";
BOOL const FORCEDAYCHARTSUPDATE         = NO; // use this only during development, default = NO

NSInteger const numberOfParticipants    = 3;

// Used in 'EcoMeterAppDelegate.m'
NSString * const CoreDataDBName         = @"ecoMeterDB.sqlite";
NSString * const SegmentedControlLabelText = @"Users";


@end
