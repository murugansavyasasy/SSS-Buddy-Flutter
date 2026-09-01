class AppEndpoint {
  static const versioncheckendpoint = "api/mobile/VersionCheckForApp";
  static const validateloginendpoint = "api/mobile/login";
  static const forgetPassword = "api/mobile/forgot-password";
  static const demolistendpoint = "GetDemosByLoginId";
  static const schoollistendpoint = "DemoMySchoolList";
  static const createdemoendpoint = "DemoCreateOrEditDemo";
  static const changepasswordendpoint = "api/mobile/change-password";
  static const getusagecount = "GetUsageReport";
  static const managementinfo = "GetManagementNumbers";
  static const circularreport = "GetVoiceCircularReport";
  static const managementvideos = "api/mobile/GetVideos";
  static const localconveyence = "/api/mobile/ViewExpenses";
  static const customerslist = "api/mobile/customers";
  static const customerinfo = "api/AppDetails/GetIndvidualCustomerInfo";
  static const schooldocuments = "api/mobile/GetSchoolDocuments";
  static const getimportantinfo = "GetImportantInfo";
  static const getAdvanceTourExpenses = "api/mobile/GetAdvanceTourExpenses";
  static const getSchoolName = "api/GetDetails/DemoGetCustomerList";
  static const getFinancialyear = "/api/mobile/financial-years";
  static const getPaymentMode = "/api/mobile/payment-modes";
  static const getInvoiceValue = "api/GetDetails/DemoGetInvoiceByCustomerID";

  static String getPoNumberByCustomer(String customerId) =>
      "api/mobile/customers/$customerId/purchase-orders";
  static String getReniwedPos(String financialYearId,
      String months,
      bool expiredNotRenewed) =>"api/mobile/renewal-po?financialYearId=$financialYearId,months=$months,expiredNotRenewed=$expiredNotRenewed";
  static const getindiualpoforapp = "api/AppDetails/GetIndvidualSchoolPoInfoForApp";
  static const demoCreateOrEdit = "DemoCreateOrEditDemo";
  static const getlocalconviencedetail = "api/GetDetails/GetLocalExpenseSummary";
  static const gettourexpensedetal = "api/GetDetails/GetTourExpenseSummary";
  static const getsalespersondetails = "api/AppDetails/GetSalesPersonDD";
  static const getreportingmembers = "api/mobile/GetReportingMembersByHierarchy";
  static String getOverallDetails(String memberId) =>
      "api/mobile/GetOverallTripDetails?UserId=$memberId";
  static const getpresignedurl = "get-s3-presigned-url";
  static const postInitiateCall = "InitiateDemoCallByDemoID";
  static const manageTrip = "/api/mobile/ManageTripDetails";
  static const updateDailyVisit = "/api/mobile/UpdateDailyVisitWithLocation";
  static const addTourexpence = "/api/mobile/ManageTourExpense";
  static const uploadfiles = "api/AppDetails/UploadExpenseFiles";
  static const createpayment = "api/mobile/payments";
  static const getalertdata = "alert_messages";
  static const demoedit = "GetDemoDetailsByDemoId";
  static const GetFeedbackRequirements = "api/AppDetails/GetFeedbackRequirements";
  static const SchoolUsageReport = "SchoolUsageReport";
  static const addLocalExpense = "api/mobile/ManageLocalExpense";
}
