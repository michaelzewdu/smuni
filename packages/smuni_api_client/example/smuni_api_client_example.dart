import 'package:smuni_api_client/smuni_api_client.dart';

void main() async {
  final client = SmuniApiClient("http://localhost:3000");
  final response = await client.signInEmail("dutch@jet.pack", "password");
  print('response: $response');
}
