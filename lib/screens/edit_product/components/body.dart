import 'package:flutter/material.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/size_config.dart';
import 'edit_product_form.dart';

class Body extends StatelessWidget {
  final Product? productToEdit;

  const Body({
    Key? key,
    required this.productToEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(10)),
                Text(
                  productToEdit == null
                      ? "Enter Product Details"
                      : "Edit Product Details",
                  style: headingStyle,
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                EditProductForm(product: productToEdit ?? Product(
                  "",
                  images: [],
                  title: "",
                  variant: "",
                  discountPrice: 0,
                  originalPrice: 0,
                  rating: 0.0,
                  highlights: "",
                  description: "",
                  seller: "",
                  owner: "",
                  productType: ProductType.Others,
                  searchTags: [],
                )),
                SizedBox(height: getProportionateScreenHeight(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
