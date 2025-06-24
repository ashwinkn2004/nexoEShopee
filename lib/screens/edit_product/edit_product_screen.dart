import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/edit_product/provider_models/ProductDetails.dart';
import 'components/body.dart';

class EditProductScreen extends StatelessWidget {
  final Product? productToEdit;

  const EditProductScreen({
    Key? key,
    required this.productToEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetails(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(productToEdit == null ? "Add Product" : "Edit Product"),
        ),
        body: Body(productToEdit: productToEdit),
      ),
    );
  }
}
