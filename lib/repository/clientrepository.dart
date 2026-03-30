import 'dart:convert';
import 'package:sssbuddy/auth/model/CreatedemoResponse.dart';
import 'package:sssbuddy/auth/model/PO_listModal.dart';
import 'package:sssbuddy/auth/model/UsageCount.dart';
import 'package:sssbuddy/repository/app_endpoint.dart';
import '../auth/model/ChangePassword.dart';
import '../auth/model/CircularModel.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../auth/model/CustomerdetailsModel.dart';
import '../auth/model/Demolist.dart';
import '../auth/model/ImportantInfoModel.dart';
import '../auth/model/LocalConveyenceModel.dart';
import '../auth/model/ManagementInfo.dart';
import '../auth/model/SchoolDocuments.dart';
import '../auth/model/Validatelogin.dart';
import '../auth/model/Versioncheck.dart';
import '../auth/model/po_details_modal.dart';
import '../core/network/DioClient.dart';
import '../auth/model/ManagementVideosModel.dart';

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
}
