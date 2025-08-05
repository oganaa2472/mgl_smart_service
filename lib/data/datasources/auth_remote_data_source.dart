import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/user_model.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../core/graphql/auth_queries.dart';
import '../../core/storage/shared_prefs_service.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password, String phoneNumber);
  Future<bool> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GraphQLClient client;
  final SharedPrefsService prefsService;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.prefsService,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(AuthQueries.login),
          variables: {
            'email': email,
            'password': password,
          },
        ),
      );

      debugPrint('Raw GraphQL Response: ${result.data}');
      
      // if (result.hasException) {
      //   debugPrint('GraphQL Errors: ${result.exception?.graphqlErrors}');
      //   debugPrint('Network Error: ${result.exception?.linkException}');
        
      //   final errorMessage = result.exception?.graphqlErrors.firstOrNull?.message ??
      //       result.exception?.linkException.toString() ??
      //       'Failed to send OTP';
            
      //   throw ServerFailure(message: errorMessage);
      // }

      final token = result.data?['login']['token'] as String;
      await prefsService.setAuthToken(token);

      // Verify the response structure
      if (isPhone) {
        final phoneResponse = result.data!['smsCode'];
        print(phoneResponse.toString());
        if (phoneResponse == null || phoneResponse['phone'] == null) {
          debugPrint('Invalid phone response structure: $phoneResponse');
          throw ServerFailure(message: 'Invalid server response for phone OTP');
        }
      } else {
        final emailResponse = result.data!['mailCode'];
        if (emailResponse == null || emailResponse['mail'] == null) {
          debugPrint('Invalid email response structure: $emailResponse');
          throw ServerFailure(message: 'Invalid server response for email OTP');
        }
      }

      return user;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password, String phoneNumber) async {
    try {
      debugPrint('Verifying OTP for contact: $contact');
      debugPrint('Is Phone: $isPhone');
      debugPrint('OTP: $otp');
      debugPrint('Contact: $contact');
      debugPrint('Variables being sent: {"username": "$contact", "password": "$otp", "types": "${isPhone ? 'phone' : 'email'}"}');
      debugPrint('GraphQL Endpoint: ${AppConstants.graphqlEndpoint}');
      debugPrint('GraphQL Mutation: ${AuthQueries.verifyOtp}');
      
      final result = await client.mutate(
        MutationOptions(
          document: gql(AuthQueries.register),
          variables: {
            'name': name,
            'email': email,
            'password': password,
            'phoneNumber': phoneNumber,
          },
        ),
      );

      debugPrint('Verify OTP Response: ${result.data}');
      debugPrint('Response keys: ${result.data?.keys.toList()}');
      if (result.data != null && result.data!['tokenAuth'] != null) {
        debugPrint('TokenAuth keys: ${result.data!['tokenAuth'].keys.toList()}');
        debugPrint('User data: ${result.data!['tokenAuth']['user']}');
      }

      if (result.hasException) {
        debugPrint('GraphQL Errors: ${result.exception?.graphqlErrors}');
        debugPrint('Network Error: ${result.exception?.linkException}');
        
        final errorMessage = result.exception?.graphqlErrors.firstOrNull?.message ?? 
                           result.exception?.linkException.toString() ?? 
                           'Invalid OTP';
        
        debugPrint('Error message: $errorMessage');
        throw ServerFailure(message: errorMessage);
      }

      final token = result.data?['register']['token'] as String;
      await prefsService.setAuthToken(token);

      final user = UserModel.fromJson(result.data?['register']['user']);
      await prefsService.setUserData(user.toJson().toString());

      return user;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<bool> logout() async {
    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(AuthQueries.logout),
        ),
      );

      if (result.hasException) {
        throw ServerFailure(
          message: result.exception?.graphqlErrors.first.message ?? 'Logout failed',
        );
      }

      await prefsService.removeAuthToken();
      await prefsService.removeUserData();
      
      return result.data?['logout']['success'] ?? false;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final result = await client.query(
        QueryOptions(
          document: gql(AuthQueries.getCurrentUser),
        ),
      );

      if (result.hasException) {
        throw ServerFailure(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to get current user',
        );
      }

      final user = UserModel.fromJson(result.data?['me']);
      await prefsService.setUserData(user.toJson().toString());
      
      return user;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
} 