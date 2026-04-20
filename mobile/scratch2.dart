void main() {
  bool _isIzinMode = true;
  bool requiresQuota = false;
  print(requiresQuota == !_isIzinMode);
}
