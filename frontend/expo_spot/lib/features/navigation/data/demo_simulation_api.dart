import 'package:expo_spot/features/navigation/data/navigation_http.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';

class DemoSimulationApi {
  DemoSimulationApi({NavigationHttp? http}) : _http = http ?? NavigationHttp();

  final NavigationHttp _http;
  static const _base = '/api/v1/demo/navigation/simulations';

  Future<DemoStateModel> createSession() async {
    final json = await _http.postJson(_base);
    return DemoStateModel.fromJson(json);
  }

  Future<DemoStateModel> fetchSession(String simulationId) async {
    final json = await _http.getJson('$_base/$simulationId');
    return DemoStateModel.fromJson(json);
  }

  Future<DemoStateModel> sendCommand({
    required String simulationId,
    required DemoCommandAction action,
    int? count,
    double? speed,
  }) async {
    final body = <String, dynamic>{'action': action.wireName};
    if (count != null) body['count'] = count;
    if (speed != null) body['speed'] = speed;

    final json = await _http.postJson('$_base/$simulationId/commands', body: body);
    return DemoStateModel.fromJson(json);
  }
}
