class AuthQueries {
  static String requestOtpEmail = '''
    mutation mailCode(\$email: String!) {
      mailCode(email: \$email) {
        __typename
        mail {
          id
        }
      }
    }
  ''';

  static String requestOtpPhone = '''
    mutation smsCode(\$phone: String!) {
      smsCode(phone: \$phone) {
        phone {
          id
        }
      }
    }
  ''';

  static String verifyOtp = '''
    mutation tokenAuth(\$username: String!, \$password: String!, \$types: String!) {
      tokenAuth(
        username: \$username,
        password: \$password,
        types: \$types
      ) {
        token
        user {
          id
          name
          email
          phoneNumber
        }
        token
      }
    }
  ''';

  static String register = '''
    mutation Register(\$name: String!, \$email: String!, \$password: String!, \$phoneNumber: String!) {
      register(input: {
        name: \$name,
        email: \$email,
        password: \$password,
        phoneNumber: \$phoneNumber
      }) {
        user {
          id
          name
          email
          phoneNumber
        }
        token
      }
    }
  ''';

  static String getCurrentUser = '''
    query GetCurrentUser {
      me {
        id
        name
        email
        phoneNumber
      }
    }
  ''';

  static String logout = '''
    mutation Logout {
      logout {
        success
        message
      }
    }
  ''';

  static String getCompaniesByCategory = '''
    query company(
      \$searchBy: [String!]
    ) {
      company(searchBy: \$searchBy) {
        id
        name
        logo
        point
        address
        category {
          id
          name
        }
        accounts {
          edges {
            node {
              accountName
              accountOwner
              iban
              account
            }
          }
        }
      }
    }
  ''';

  static String createCompany = '''
    mutation createCompany(
      \$name: String!,
      \$address: String!,
      \$logo: String
    ) {
      createCompany(name: \$name, address: \$address, logo: \$logo) {
        id
        name
        address
        logo
      }
    }
  ''';
} 