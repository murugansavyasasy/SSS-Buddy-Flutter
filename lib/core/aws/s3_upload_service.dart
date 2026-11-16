import 'dart:io';

import 'package:dio/dio.dart';

import '../../repository/app_endpoint.dart';
import '../network/DioClient.dart';
import 'aws_key.dart';
import 'upload_response.dart';

/// Uploads a local file to S3 in two steps:
///   1. GET a presigned URL from [AwsKey.prisigned_url] +
///      [AppEndpoint.getpresignedurl].
///   2. PUT the file to S3 with that presigned URL (streamed, not read into
///      memory).
///
/// Returns the uploaded object's `fileUrl`. Errors surface as [ApiException].
class S3UploadService {
  S3UploadService(this._client);

  final DioClient _client;

  /// Step 1: ask the API for a presigned PUT URL.
  Future<UploadData> getPresignedUrl({
    required String fileName,
    required String bucketPath,
    required String fileType,
    String bucket = '',
  }) async {
    // Presign API base comes from AwsKey.prisigned_url (absolute URL, so it
    // overrides the AWS Dio's own baseUrl).
    final response = await _client.awsGet(
      '${AwsKey.prisigned_url}${AppEndpoint.getpresignedurl}',
      query: {
        'bucket': bucket.isEmpty ? AwsKey.SCHOOL_CHIMES_COMMUNICATION : bucket,
        'fileName': fileName,
        'bucketPath': bucketPath,
        'fileType': fileType,
      },
    );

    final body = response.data;
    final parsed = UploadResponse.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const {},
    );
    final data = parsed.data;
    if (data?.presignedUrl == null || data?.fileUrl == null) {
      throw ApiException(
        parsed.message ?? 'Server did not return a valid upload URL.',
      );
    }
    return data!;
  }

  /// Step 2: PUT the file to S3. [contentType] must match the `fileType`
  /// used for the presigned URL.
  Future<void> putFile({
    required String presignedUrl,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final length = await file.length();
    try {
      await _client.s3Dio.put(
        presignedUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: length,
          },
          // Large recordings on slow networks need more than the default 30 s.
          sendTimeout: const Duration(minutes: 5),
          followRedirects: false,
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiException) throw err;
      throw ApiException('Upload failed. Please try again.',
          statusCode: e.response?.statusCode);
    }
  }

  /// Presign + upload. Returns the uploaded file's URL.
  Future<String> uploadFile({
    required File file,
    required String fileName,
    required String bucketPath,
    required String contentType,
    String bucket = '',
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!await file.exists()) {
      throw ApiException('The file to upload is missing.');
    }
    final data = await getPresignedUrl(
      fileName: fileName,
      bucketPath: bucketPath,
      fileType: contentType,
      bucket: bucket,
    );
    await putFile(
      presignedUrl: data.presignedUrl!,
      file: file,
      contentType: contentType,
      onProgress: onProgress,
    );
    return data.fileUrl!;
  }
}
