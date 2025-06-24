import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_short_detail_card.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/CartItem.dart';
import 'package:nexoeshopee/models/OrderedProduct.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/cart/components/checkout_card.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/services/data_streams/cart_items_stream.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';

import '../../../utils.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final CartItemsStream cartItemsStream = CartItemsStream();
  PersistentBottomSheetController? bottomSheetHandler;

  @override
  void initState() {
    super.initState();
    cartItemsStream.init();
  }

  @override
  void dispose() {
    cartItemsStream.dispose();
    super.dispose();
  }

  Future<void> refreshPage() async {
    cartItemsStream.reload();
  }

  void shutBottomSheet() {
    if (bottomSheetHandler != null) {
      bottomSheetHandler?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(screenPadding)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: getProportionateScreenHeight(10)),
                  Text("Your Cart", style: headingStyle),
                  SizedBox(height: getProportionateScreenHeight(20)),
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.75,
                    child: buildCartItemsList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCartItemsList() {
    return StreamBuilder<List<String>>(
      stream: cartItemsStream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final cartItemsId = snapshot.data!;
          if (cartItemsId.isEmpty) {
            return Center(
              child: NothingToShowContainer(
                iconPath: "assets/icons/empty_cart.svg",
                secondaryMessage: "Your cart is empty",
              ),
            );
          }

          return Column(
            children: [
              DefaultButton(
                text: "Proceed to Payment",
                press: () {
                  bottomSheetHandler = Scaffold.of(context).showBottomSheet(
                    (context) {
                      return CheckoutCard(
                        onCheckoutPressed: checkoutButtonCallback,
                      );
                    },
                  );
                },
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cartItemsId.length,
                  itemBuilder: (context, index) {
                    return buildCartItemDismissible(
                        context, cartItemsId[index], index);
                  },
                ),
              ),
            ],
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Center(
            child: NothingToShowContainer(
              iconPath: "assets/icons/network_error.svg",
              primaryMessage: "Something went wrong",
              secondaryMessage: "Unable to connect to Database",
            ),
          );
        }
      },
    );
  }

  Widget buildCartItemDismissible(
      BuildContext context, String cartItemId, int index) {
    return Dismissible(
      key: Key(cartItemId),
      direction: DismissDirection.startToEnd,
      dismissThresholds: {
        DismissDirection.startToEnd: 0.65,
      },
      background: buildDismissibleBackground(),
      child: buildCartItem(cartItemId),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final confirm = await showConfirmationDialog(
              context, "Remove Product from Cart?");
          if (confirm) {
            bool result = false;
            String msg = "Something went wrong";
            try {
              result =
                  await UserDatabaseHelper().removeProductFromCart(cartItemId);
              if (result) {
                msg = "Product removed from cart successfully";
                await refreshPage();
              }
            } catch (e) {
              Logger().e(e.toString());
            } finally {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(msg),
              ));
            }
            return result;
          }
        }
        return false;
      },
    );
  }

  Widget buildCartItem(String cartItemId) {
    return FutureBuilder<Product?>(
      future: ProductDatabaseHelper().getProductWithID(cartItemId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final product = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: kTextColor.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 8,
                  child: ProductShortDetailCard(
                    productId: product.id,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                            key: Key(product.id),
                            productId: product.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                buildItemCountControl(cartItemId),
              ],
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          Logger().w(snapshot.error.toString());
          return const Icon(Icons.error);
        }
      },
    );
  }

  Widget buildItemCountControl(String cartItemId) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        decoration: BoxDecoration(
          color: kTextColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            InkWell(
              child: const Icon(Icons.arrow_drop_up, color: kTextColor),
              onTap: () => arrowUpCallback(cartItemId),
            ),
            const SizedBox(height: 8),
            FutureBuilder<CartItem?>(
              future: UserDatabaseHelper().getCartItemFromId(cartItemId),
              builder: (context, snapshot) {
                final count = snapshot.data?.itemCount ?? 0;
                return Text(
                  "$count",
                  style: const TextStyle(
                      color: kPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                );
              },
            ),
            const SizedBox(height: 8),
            InkWell(
              child: const Icon(Icons.arrow_drop_down, color: kTextColor),
              onTap: () => arrowDownCallback(cartItemId),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDismissibleBackground() {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 4),
          Text("Delete",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> checkoutButtonCallback() async {
    shutBottomSheet();
    final confirm = await showConfirmationDialog(
        context,
        "This is just a Project Testing App so, no actual Payment Interface is available.\nDo you want to proceed for Mock Ordering of Products?");
    if (!confirm) return;

    final orderFuture = UserDatabaseHelper().emptyCart();
    await showDialog(
      context: context,
      builder: (context) => AsyncProgressDialog(
        orderFuture,
        message: const Text("Placing the Order"),
      ),
    );

    try {
      final orderedProductsUid = await orderFuture;
      if (orderedProductsUid != null) {
        final now = DateTime.now();
        final formatted = "${now.day}-${now.month}-${now.year}";
        final orders = orderedProductsUid
            .map((e) => OrderedProduct('', productUid: e, orderDate: formatted))
            .toList();

        final added = await UserDatabaseHelper().addToMyOrders(orders);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              added ? "Products ordered Successfully" : "Order failed."),
        ));
      }
    } catch (e) {
      Logger().e(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }

    await refreshPage();
  }

  Future<void> arrowUpCallback(String cartItemId) async {
    shutBottomSheet();
    final future = UserDatabaseHelper().increaseCartItemCount(cartItemId);
    await showDialog(
      context: context,
      builder: (_) => AsyncProgressDialog(future, message: const Text("Please wait")),
    );
    await refreshPage();
  }

  Future<void> arrowDownCallback(String cartItemId) async {
    shutBottomSheet();
    final future = UserDatabaseHelper().decreaseCartItemCount(cartItemId);
    await showDialog(
      context: context,
      builder: (_) => AsyncProgressDialog(future, message: const Text("Please wait")),
    );
    await refreshPage();
  }
}
