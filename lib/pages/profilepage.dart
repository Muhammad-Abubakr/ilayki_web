import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ilayki_web/blocs/products/products_bloc.dart';
import 'package:ilayki_web/models/product.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../blocs/authenticate/authenticate_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool editing = false;
  bool editingProduct = false;
  Product? editedProduct;
  bool sortAscending = false;
  bool addProduct = false;
  int columnSortIndex = 0;

  late ProductsBloc productsBloc;
  late AuthenticateBloc authenticateBloc;
  List<Product>? products;

  Uint8List? _pfp;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Uint8List? _productImage;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  @override
  void didChangeDependencies() {
    productsBloc = BlocProvider.of<ProductsBloc>(context, listen: true);
    authenticateBloc = BlocProvider.of<AuthenticateBloc>(context);
    products = productsBloc.state.products;

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final navigatorState = Navigator.of(context);
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocBuilder<AuthenticateBloc, AuthenticateState>(
        builder: (context, state) {
          _nameController.value =
              TextEditingValue(text: state.user!.displayName!);
          _emailController.value = TextEditingValue(text: state.user!.email!);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductTable(productsBloc),
              if (!addProduct && !editingProduct) ...[
                _buildProfileEditingWidget(size, state),
              ] else ...[
                BlocListener<ProductsBloc, ProductsState>(
                  listener: (context, state) {
                    switch (state.runtimeType) {
                      case ProductsError:
                        scaffoldMessengerState.showSnackBar(SnackBar(
                          content: Text(
                            "${state.error}",
                            textAlign: TextAlign.center,
                          ),
                        ));
                        break;
                      case ProductsProcessing:
                        navigatorState.push(DialogRoute(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ));
                        break;
                      case ProductsPopulate:
                        navigatorState.pop();
                        setState(() {
                          addProduct = false;
                          editingProduct = false;
                          editedProduct = null;
                        });
                        break;
                    }
                  },
                  child: editingProduct
                      ? _buildProductEditingWidget(productsBloc, size, state)
                      : _buildAddItemWidget(productsBloc, size, state),
                ),
              ]
            ],
          );
        },
      ),
    );
  }

  _pickImage(String dest) async {
    final picked = await ImagePickerWeb.getImageAsBytes();
    if (picked != null) {
      setState(() => dest == "pfp" ? _pfp = picked : _productImage = picked);
    }
  }

  _buildProfileEditingWidget(Size size, AuthenticateState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      child: SizedBox(
        width: max(250, size.width * 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _pfp != null
                      ? Image.memory(_pfp!, fit: BoxFit.cover)
                      : Image.network(state.user!.photoURL!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 48),
              if (editing)
                ElevatedButton(
                  onPressed: () => _pickImage("pfp"),
                  child: const Text("Upload a Picture"),
                ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                enabled: editing,
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: editing,
                decoration: const InputDecoration(
                  label: Text("Email"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.text,
                enabled: editing,
                decoration: const InputDecoration(
                  label: Text("Update Password"),
                ),
              ),
              const SizedBox(height: 64),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    editingProduct = false;
                    addProduct = false;

                    editing = !editing;
                    _passwordController.clear();
                    _pfp = null;
                  }),
                  child: Text(editing ? "Cancel" : "Edit Profile"),
                ),
                if (editing)
                  ElevatedButton(
                    onPressed: () => authenticateBloc.add(UpdateEvent(
                      pfp: _pfp,
                      email: _emailController.text.trim(),
                      displayName: _nameController.text.trim(),
                      password: _passwordController.text.trim(),
                    )),
                    child: const Text("Save"),
                  ),
              ]),
              if (!editing) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => authenticateBloc.add(DeleteEvent()),
                  child: const Text("Purge User"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTable(ProductsBloc productsBloc) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Products",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      editing = false;
                      editingProduct = false;
                      addProduct = !addProduct;

                      _productNameController.clear();
                      _priceController.clear();
                      _stockController.clear();
                    }),
                    label: Text(addProduct ? "Cancel" : "Add Product"),
                    icon: Icon(addProduct ? Icons.cancel : Icons.add),
                  )
                ],
              ),
            ),
            Card(
              elevation: 4,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                dataRowMinHeight: 100,
                dataRowMaxHeight: 100,
                sortAscending: sortAscending,
                sortColumnIndex: columnSortIndex,
                dividerThickness: 1,
                columns: <DataColumn>[
                  DataColumn(label: const Text("ID"), onSort: onSort),
                  const DataColumn(label: Text("Product Picture")),
                  DataColumn(label: const Text("Name"), onSort: onSort),
                  DataColumn(label: const Text("Price"), onSort: onSort),
                  DataColumn(label: const Text("Stock"), onSort: onSort),
                  const DataColumn(label: Text("Actions")),
                ],
                rows: productsBloc.state.runtimeType == ProductsPopulate ||
                        productsBloc.state.runtimeType == ProductsProcessing
                    ? products!
                        .map((product) => DataRow(cells: [
                              DataCell(Text(product.pid)),
                              DataCell(
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(product.productImage,
                                          fit: BoxFit.cover)),
                                ),
                              ),
                              DataCell(Text(product.name)),
                              DataCell(Text(product.price.toString())),
                              DataCell(Text(product.quantity.toString())),
                              DataCell(
                                IconButton(
                                  onPressed: () => setState(() {
                                    editing = false;
                                    addProduct = false;

                                    editingProduct = !editingProduct;
                                    editedProduct =
                                        editingProduct ? product : null;

                                    _productNameController.value =
                                        TextEditingValue(text: product.name);
                                    _priceController.value = TextEditingValue(
                                        text: product.price.toString());
                                    _stockController.value = TextEditingValue(
                                        text: product.quantity.toString());
                                  }),
                                  icon: Icon(editingProduct
                                      ? Icons.edit_off
                                      : Icons.edit),
                                ),
                              ),
                            ]))
                        .toList()
                    : const <DataRow>[],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildAddItemWidget(
      ProductsBloc productsBloc, Size size, AuthenticateState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      child: SizedBox(
        width: max(250, size.width * 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _productImage != null
                      ? Image.memory(_productImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Upload an image to show here",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _pickImage("product"),
                child: const Text("Upload a Picture"),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _productNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  label: Text("Product Name"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text("Price"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text("Stock"),
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () {
                  if (_productNameController.text.isNotEmpty &&
                      _priceController.text.isNotEmpty &&
                      _stockController.text.isNotEmpty &&
                      _productImage != null) {
                    productsBloc.add(PostProduct(
                      name: _productNameController.text.trim(),
                      price: _priceController.text.trim(),
                      stock: _stockController.text.trim(),
                      productImage: _productImage!,
                    ));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildProductEditingWidget(
      ProductsBloc productsBloc, Size size, AuthenticateState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      child: SizedBox(
        width: max(250, size.width * 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _productImage != null
                      ? Image.memory(_productImage!, fit: BoxFit.cover)
                      : Image.network(editedProduct!.productImage,
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _pickImage("product"),
                child: const Text("Upload a Picture"),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _productNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  label: Text("Product Name"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text("Price"),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text("Stock"),
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () {
                  productsBloc.add(UpdateProduct(
                    product: editedProduct!,
                    name: _productNameController.text.trim(),
                    price: _priceController.text.trim(),
                    stock: _stockController.text.trim(),
                    productImage: _productImage,
                  ));
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      columnSortIndex = columnIndex;
      sortAscending = ascending;

      switch (columnIndex) {
        case 0:
          products!.sort((a, b) => a.pid.compareTo(b.pid));
          break;
        case 2:
          products!.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 3:
          products!.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 4:
          products!.sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
      }

      if (!ascending) {
        products = products!.reversed.toList();
      }
    });
  }
}
