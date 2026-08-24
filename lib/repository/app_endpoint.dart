class AppEndpoint {
  static const versioncheckendpoint = "/api/AppDetails/VersionCheckForApp";
  static const validateloginendpoint = "api/mobile/login";
  static const demolistendpoint = "GetDemosByLoginId";
  static const schoollistendpoint = "DemoMySchoolList";
  static const createdemoendpoint = "DemoCreateOrEditDemo";
  static const changepasswordendpoint = "api/AppDetails/ChangePassword";
  static const getusagecount = "GetUsageReport";
  static const managementinfo = "GetManagementNumbers";
  static const circularreport = "GetVoiceCircularReport";
  static const managementvideos = "api/AppDetails/GetVideos";
  static const localconveyence = "/api/mobile/ViewExpenses";
  static const customerslist = "api/mobile/customers";
  static const customerinfo = "api/AppDetails/GetIndvidualCustomerInfo";
  static const schooldocuments = "api/AppDetails/GetSchoolDocuments";
  static const getimportantinfo = "GetImportantInfo";
  static const getAdvanceTourExpenses = "api/mobile/GetAdvanceTourExpenses";
  static const getSchoolName = "api/GetDetails/DemoGetCustomerList";
  static const getFinancialyear = "/api/mobile/financial-years";
  static const getPaymentMode = "/api/mobile/payment-modes";
  static const getInvoiceValue = "api/GetDetails/DemoGetInvoiceByCustomerID";

  static String getPoNumberByCustomer(String customerId) =>
      "api/mobile/customers/$customerId/purchase-orders";
  static const getindiualpoforapp = "api/AppDetails/GetIndvidualSchoolPoInfoForApp";
  static const demoCreateOrEdit = "DemoCreateOrEditDemo";
  static const getlocalconviencedetail = "api/GetDetails/GetLocalExpenseSummary";
  static const gettourexpensedetal = "api/GetDetails/GetTourExpenseSummary";
  static const getsalespersondetails = "api/AppDetails/GetSalesPersonDD";
  static const getreportingmembers = "api/AppDetails/GetReportingMembersByHierarchy";
  static const getOverallDetails = "api/AppDetails/GetOverallTripDetails";
  static const getpresignedurl = "get-s3-presigned-url";
  static const postInitiateCall = "InitiateDemoCallByDemoID";
  static const manageTrip = "api/AppDetails/ManageTripDetails";
  static const updateDailyVisit = "api/AppDetails/UpdateDailyVisitWithLocation";
  static const addTourexpence = "/api/mobile/ManageTourExpense";
  static const uploadfiles = "api/AppDetails/UploadExpenseFiles";
  static const createpayment = "api/mobile/payments";
  static const getalertdata = "alert_messages";
  static const demoedit = "GetDemoDetailsByDemoId";
  static const GetFeedbackRequirements = "api/AppDetails/GetFeedbackRequirements";
  static const SchoolUsageReport = "SchoolUsageReport";
}
