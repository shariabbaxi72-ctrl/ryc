import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../expert/views/expert_add_car_view.dart';

class AdminVehicleScreen extends StatefulWidget {
  final String adminName; // Dynamic naam ke liye
  const AdminVehicleScreen({super.key, required this.adminName});

  @override
  State<AdminVehicleScreen> createState() => _AdminVehicleScreenState();
}

class _AdminVehicleScreenState extends State<AdminVehicleScreen> {
  String currentSection = "Existing Car";
  String openBrand = "";

  List<dynamic> pendingCars = [];
  List<dynamic> allApprovedCars = [];
  bool isLoadingRequests = false;
  bool isLoadingExisting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
    _loadAllApprovedCars();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      var data = await ApiService.fetchPendingVehicles();
      setState(() { pendingCars = data; isLoadingRequests = false; });
    } catch (e) { setState(() => isLoadingRequests = false); }
  }

  Future<void> _loadAllApprovedCars() async {
    setState(() => isLoadingExisting = true);
    try {
      var data = await ApiService.fetchAllVehicles();

      setState(() {
        // Agar API mein status field nahi aa rahi, toh sari cars ko 'approved' maan lein
        // Ya phir agar aapko sirf specific cars chahiye, toh logic change karein
        allApprovedCars = data;
        isLoadingExisting = false;
      });
    } catch (e) {
      print("Error loading: $e");
      setState(() => isLoadingExisting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildVehicleTabs(),
              const SizedBox(height: 25),
              Expanded(
                child: currentSection == "Existing Car"
                    ? _buildExistingCarsList()
                    : currentSection == "Add New Car"
                    ? ExpertAddCarView(
                  isAdmin: true,
                  onCarAdded: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Car Added!")));
                    _loadAllApprovedCars();
                    setState(() => currentSection = "Existing Car");
                  },
                )
                    : _buildRequestCarList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            Text(widget.adminName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestCarList() {
    if (isLoadingRequests) return const Center(child: CircularProgressIndicator());
    if (pendingCars.isEmpty) return const Center(child: Text("No pending requests."));

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        itemCount: pendingCars.length,
        itemBuilder: (context, index) {
          var car = pendingCars[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${car['make'] ?? ''} ${car['model'] ?? ''}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Variant: ${car['variant'] ?? ''} | Year: ${car['year'] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ])),
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: () async {
                  if (await ApiService.approveVehicle(car['vid'])) { _loadPendingRequests(); _loadAllApprovedCars(); }
                }),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red, size: 30), onPressed: () async {
                  if (await ApiService.deleteVehicle(car['vid'])) { _loadPendingRequests(); }
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingCarsList() {
    if (isLoadingExisting) return const Center(child: CircularProgressIndicator());
    if (allApprovedCars.isEmpty) return const Center(child: Text("No approved cars found."));

    var distinctMakes = allApprovedCars.map((c) => c['make'].toString()).toSet().toList();

    return RefreshIndicator(
      onRefresh: _loadAllApprovedCars,
      child: ListView.builder(
        itemCount: distinctMakes.length,
        itemBuilder: (context, index) {
          String make = distinctMakes[index];
          var cars = allApprovedCars.where((c) => c['make'] == make).toList();
          return Column(children: [_brandDropdown(make, cars), const SizedBox(height: 15)]);
        },
      ),
    );
  }

  Widget _brandDropdown(String brandName, List<dynamic> cars) {
    bool isOpen = openBrand == brandName;
    return Column(children: [
      GestureDetector(onTap: () => setState(() => openBrand = isOpen ? "" : brandName), child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [const Icon(Icons.directions_car), const SizedBox(width: 15), Text(brandName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), Icon(isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)]),
      )),
      if (isOpen) Container(padding: const EdgeInsets.all(10), color: Colors.grey.shade50, child: Column(children: cars.map((c) => ListTile(title: Text("${c['model']} (${c['year']})"), subtitle: Text(c['variant'] ?? ""))).toList()))
    ]);
  }

  Widget _buildVehicleTabs() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(children: ["Existing Car", "Add New Car", "Request of car"].map((t) => Expanded(
        child: InkWell(onTap: () => setState(() => currentSection = t), child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: currentSection == t ? const Color(0xFF001F3F) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(t, style: TextStyle(fontSize: 11, color: currentSection == t ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
        )),
      )).toList()),
    );
  }
}