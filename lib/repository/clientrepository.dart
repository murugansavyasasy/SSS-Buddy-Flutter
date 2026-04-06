import 'dart:convert';
import 'package:sssbuddy/auth/model/CreatedemoResponse.dart';
import 'package:sssbuddy/auth/model/UsageCount.dart';
import 'package:sssbuddy/repository/app_endpoint.dart';
import '../auth/model/AdvanceTourExpenseDetailModel.dart';
import '../auth/model/AdvanceTourExpenseModel.dart';
import '../auth/model/ChangePassword.dart';
import '../auth/model/CircularModel.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../auth/model/CustomerdetailsModel.dart';
import '../auth/model/Demolist.dart';
import '../auth/model/FinancialYearModel.dart';
import '../auth/model/ImportantInfoModel.dart';
import '../auth/model/InvoiceModel.dart';
import '../auth/model/LocalConveyenceModel.dart';
import '../auth/model/LocalExpenseDetailModel.dart';
import '../auth/model/ManagementInfo.dart';
import '../auth/model/OverallTripDetailsModel.dart';
import '../auth/model/PO_listModal.dart';

import '../auth/model/ReportingMembersModel.dart';
import '../auth/model/SalesPersonModel.dart';
import '../auth/model/SchoolDocuments.dart';
import '../auth/model/SchoolNameModel.dart';
import '../auth/model/Validatelogin.dart';
import '../auth/model/Versioncheck.dart';
import '../auth/model/po_details_modal.dart';
import '../core/network/DioClient.dart';
import '../auth/model/ManagementVideosModel.dart';
import '../viewModel/invoice_dd_viewmodel.dart';

class ClientRepository {
  final Dioclient client;
  ClientRepository(this.client);
  Future<Versioncheck> getVersionCheckDetails() async {
    final response = await client.get(
      AppEndpoint.versioncheckendpoint,
      query: {"VersionID": "55"},
    );
    return Versioncheck.fromJson(response.data);
  }

  Future<Validatelogin> apilogin(String employeeId, String password) async {
    final response = await client.post(
      AppEndpoint.validateloginendpoint,
      body: {"EmployeeId": employeeId, "Password": password},
    );
    return Validatelogin.fromJson(response.data);
  }

  Future<List<Demolist>> getdemolist(String schoolLoginId) async {
    final response = await client.get(
      AppEndpoint.demolistendpoint,
      query: {"LoginID": schoolLoginId},
      useSchoolApi: true,
    );

    final List data = response.data;

    return data.map((e) => Demolist.fromJson(e)).toList();
  }

  Future<String> postschoollist(String schoolLoginId) async {
    final response = await client.post(
      AppEndpoint.schoollistendpoint,
      body: {"LoginID": schoolLoginId},
      useSchoolApi: true,
    );

    return jsonEncode(response.data);
  }

  Future<Createdemoresponse> createdemo(
    String LoginID,
    String SchoolName,
    String MobileNo,
    String Email,
    String ParentNos,
    String RequestType,
  ) async {
    final response = await client.post(
      AppEndpoint.createdemoendpoint,
      body: {
        "LoginID": LoginID,
        "SchoolName": SchoolName,
        "MobileNo": MobileNo,
        "Email": Email,
        "ParentNos": ParentNos,
        "RequestType": RequestType,
      },
      useSchoolApi: true,
    );

    final List data = response.data;

    return Createdemoresponse.fromJson(data.first);
  }

  Future<Changepassword> changepassword(
    String idUser,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await client.get(
      AppEndpoint.changepasswordendpoint,
      query: {
        "idUser": idUser,
        "OldPassword": oldPassword,
        "NewPassword": newPassword,
      },
      useSchoolApi: false,
    );

    final List<dynamic> list = response.data as List<dynamic>;
    return Changepassword.fromJson(list[0]);
  }

  Future<Usagecount> usagecount(
    String schoolID,
    String fromDate,
    String toDate,
  ) async {
    final response = await client.post(
      AppEndpoint.getusagecount,
      body: {"schoolID": schoolID, "FromDate": fromDate, "ToDate": toDate},
      useSchoolApi: true,
    );

    return Usagecount.fromJson(response.data[0]);
  }

  Future<List<Managementinfo>> managementinfo(int schoolID) async {
    final response = await client.get(
      AppEndpoint.managementinfo,
      query: {"Schoolid": schoolID},
      useSchoolApi: true,
    );
    return (response.data as List)
        .map((e) => Managementinfo.fromJson(e))
        .toList();
  }

  Future<List<Circularmodel>> getcircularlist(String schoolLoginId) async {
    final response = await client.post(
      AppEndpoint.circularreport,
      body: {"LoginID": schoolLoginId},
      useSchoolApi: true,
    );
    final List data = response.data;
    return data.map((e) => Circularmodel.fromJson(e)).toList();
  }

  Future<List<Managementvideosmodel>> getmanagementvideos(
    String vimIdUSer,
  ) async {
    final response = await client.get(
      AppEndpoint.managementvideos,
      query: {"UserId": vimIdUSer},
    );
    final List data = response.data;
    return data.map((e) => Managementvideosmodel.fromJson(e)).toList();
  }

  Future<List<Customerdetailsmodel>> getcustomerslist(
    String VimIdUser,
    String customerId,
    String selectedUser,
  ) async {
    final response = await client.post(
      AppEndpoint.customerslist,
      body: {
        "idUser": VimIdUser,
        "customerId": customerId,
        "selectedUser": selectedUser,
      },
    );

    final List data = response.data;

    return data.map((e) => Customerdetailsmodel.fromJson(e)).toList();
  }

  Future<List<Customerdetailsinfomodelclass>> getcustomerinfo(
    String VimIdUser,
    String customerId,
    String selectedUser,
  ) async {
    final response = await client.post(
      AppEndpoint.customerinfo,
      body: {
        "idUser": VimIdUser,
        "customerId": customerId,
        "selectedUser": selectedUser,
      },
    );

    final List data = response.data;

    return data.map((e) => Customerdetailsinfomodelclass.fromJson(e)).toList();
  }

  Future<List<Schooldocuments>> getSchoolDocuments(String vimIDuser) async {
    final response = await client.get(
      AppEndpoint.schooldocuments,
      query: {"UserId": vimIDuser},
    );

    final List data = response.data;

    return data.map((e) => Schooldocuments.fromJson(e)).toList();
  }

  Future<List<Importantinfomodel>> getImportantInfo() async {
    final response = await client.get(
      AppEndpoint.getimportantinfo,
      useSchoolApi: true,
    );

    final List<dynamic> data = response.data;
    if (data.isEmpty) {
      return [];
    }
    final Map<String, dynamic> jsonData = data.first as Map<String, dynamic>;
    return [Importantinfomodel.fromJson(jsonData)];
  }


  Future<List<Localconveyencemodel>> getlocalconveyence(
      String vimIdUSer,
      ) async {
    final response = await client.get(
      AppEndpoint.localconveyence,
      query: {"idUser": vimIdUSer},
    );
    final List data = response.data;
    return data.map((e) => Localconveyencemodel.fromJson(e)).toList();
  }


  Future<List<Advancetourexpensemodel>> getadvancetourdata(String VimsIdUser) async {
    final response = await client.get(
      AppEndpoint.getAdvanceTourExpenses,
      query: {"idUser": VimsIdUser},
    );

    final List data = response.data;

    return data.map((e) => Advancetourexpensemodel.fromJson(e)).toList();
  }


  Future<List<Schoolnamemodel>> getschoolname(String VimsIdUser) async {
    final response = await client.get(
      AppEndpoint.getSchoolName,
      query: {"CustomerType" : 1,"LoginId": VimsIdUser},
    );

    final List data = response.data;

    return data.map((e) => Schoolnamemodel.fromJson(e)).toList();
  }


  Future<List<Financialyearmodel>> getfinancialyear() async {
    final response = await client.get(
      AppEndpoint.getFinancialyear,
    );

    final List data = response.data;

    return data.map((e) => Financialyearmodel.fromJson(e)).toList();
  }

  Future<List<Invoicemodel>> getinvoicevalue(String customerId) async {
    final response = await client.get(
      AppEndpoint.getInvoiceValue,
      query: {"customerId": customerId},

    );

    final List data = response.data;

    return data.map((e) => Invoicemodel.fromJson(e)).toList();
  }


  Future<List<PoListModel>> getpolist(String cusId) async {
    final response = await client.get(
      AppEndpoint.getponummerbycustomer,
      query: {"cusId": cusId},
    );

    final List data = response.data;

    return data.map((e) => PoListModel.fromJson(e)).toList();
  }
  Future<List<PoDetailsModel>> getpodetails(
      String VimIdUser,
      String purchaseOrderId,
      ) async {
    final response = await client.post(
      AppEndpoint.getindiualpoforapp,
      body: {
        "idUser": VimIdUser,
        "PurchaseOrderID": purchaseOrderId,
      },
    );

    final List data = response.data;

    return data.map((e) => PoDetailsModel.fromJson(e)).toList();
  }


  Future<List<Localexpensedetailmodel>> getlocalconviencedetail(
      String idLocalExpense,
      ) async {
    final response = await client.get(
      AppEndpoint.getlocalconviencedetail,
      query: {"idLocalExpense": idLocalExpense},
    );
    final List data = response.data;
    return data.map((e) => Localexpensedetailmodel.fromJson(e)).toList();
  }


  Future<List<Advancetourexpensedetailmodel>> getadvancetourdetails(
      String idTourExpense,
      ) async {
    final response = await client.get(
      AppEndpoint.gettourexpensedetal,
      query: {"idTourExpense" : idTourExpense,"cmd": "Advance"},

    );
    final List data = response.data;
    return data.map((e) => Advancetourexpensedetailmodel.fromJson(e)).toList();
  }


  Future<List<Salespersonmodel>> getsalesperson(String IdUser) async {
    final response = await client.get(
      AppEndpoint.getsalespersondetails,
      query: {"idUser" : IdUser},
    );

    final List data = response.data;

    return data.map((e) => Salespersonmodel.fromJson(e)).toList();
  }

  Future<List<Reportingmembersmodel>> getreportingmembers(String IdUser) async {
    final response = await client.get(
      AppEndpoint.getsalespersondetails,
      query: {"UserId" : IdUser},
    );

    final List data = response.data;

    return data.map((e) => Reportingmembersmodel.fromJson(e)).toList();
  }

  Future<List<Overalltripdetailsmodel>> getoveralldetails(String idMember) async {
    final response = await client.get(
      AppEndpoint.getsalespersondetails,
      query: {"UserId" : idMember},
    );

    final List data = response.data;

    return data.map((e) => Overalltripdetailsmodel.fromJson(e)).toList();
  }
}


