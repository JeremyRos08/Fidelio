class ProductSearchUriService {
  ProductSearchUriService._();

  static Uri idealo(String searchTerm) {
    return Uri.https('www.idealo.fr', '/prechcat.html', {'q': searchTerm});
  }
}
