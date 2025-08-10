// Raw API provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
