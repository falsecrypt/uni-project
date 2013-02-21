

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

NSString *  const currentCostServerBaseURLString = @"http://www.hcm-lab.de/downloads/buehling/adaptiveart/CurrentCostTreeOnline/";
NSString *  const currentCostServerBaseURLHome   = @"www.hcm-lab.de";
float     const OfficeArea     = 20.0f;
NSInteger const FirstSensorID  = 3;
NSInteger const SecondSensorID = 4;
NSInteger const ThirdSensorID  = 5;

// Energy-Label: levels/ranks
NSInteger const APlusPlusPlus  = 1;
NSInteger const APlusPlus      = 2;
NSInteger const APlus          = 3;
NSInteger const A              = 4;
NSInteger const B              = 5;
NSInteger const C              = 6;
NSInteger const D              = 7;

// test data flag, set to NO when not in dev mode
BOOL USEDUMMYDATA              = YES;

@end
