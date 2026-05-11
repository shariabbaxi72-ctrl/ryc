import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> myCars;
  final List<Map<String, dynamic>> allProblems;
  final String? selectedCar;
  final String? selectedProblem;
  final Function(String?) onCarChanged;
  final Function(String?) onProblemChanged;
  final VoidCallback onFindExpert;
  final Future<void> Function() onRefresh;

  const DashboardView({
    super.key,
    required this.myCars,
    required this.allProblems,
    required this.selectedCar,
    required this.selectedProblem,
    required this.onCarChanged,
    required this.onProblemChanged,
    required this.onFindExpert,
  required this.onRefresh,

  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Controllers to control expansion state
  final ExpansionTileController _headlightCtrl = ExpansionTileController();
  final ExpansionTileController _hornCtrl = ExpansionTileController();
  final ExpansionTileController _indicatorCtrl = ExpansionTileController();

  void _handleSearchSelection(String pTitle) {
    widget.onProblemChanged(pTitle);
    setState(() {
      _searchController.text = pTitle;
      searchText = "";
    });

    // Close all, then open specific based on title match
    _headlightCtrl.collapse();
    _hornCtrl.collapse();
    _indicatorCtrl.collapse();

    String titleLower = pTitle.toLowerCase();
    if (titleLower.contains("headlight")) _headlightCtrl.expand();
    else if (titleLower.contains("horn")) _hornCtrl.expand();
    else if (titleLower.contains("indicator")) _indicatorCtrl.expand();

    FocusScope.of(context).unfocus();
  }




  @override
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        color: const Color(0xFF1B2E4B),
        onRefresh: widget.onRefresh, // Parent wala function yahan call hoga
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Pull-to-refresh ke liye zaroori hai
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Your Car", style: TextStyle(fontSize: 12, color: Colors.grey)),
              _dropdownBox(),
              // ... Baqi pura code same ...
          const SizedBox(height: 20),

          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => searchText = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Search problem...",
              border: OutlineInputBorder(),
            ),
          ),


          if (searchText.isNotEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
              child: ListView.builder(
                itemCount: widget.allProblems.where((p) => (p['ptitle'] ?? "").toLowerCase().contains(searchText.toLowerCase())).length,
                itemBuilder: (context, index) {
                  var item = widget.allProblems.where((p) => (p['ptitle'] ?? "").toLowerCase().contains(searchText.toLowerCase())).toList()[index];
                  return ListTile(
                    title: Text(item['ptitle']),
                    onTap: () => _handleSearchSelection(item['ptitle']),
                  );
                },
              ),
            ),

          const SizedBox(height: 30),
          _categorySection("Headlight", ["Headlight Off", "Headlight Low", "Headlight Blinking"], _headlightCtrl),
          _categorySection("Horn", ["Horn Not Working", "Horn Low Sound"], _hornCtrl),
          _categorySection("Indicator", ["Indicator Not Working", "One Side Indicator Not Working"], _indicatorCtrl),

          const SizedBox(height: 30),
          _filledBtn("Find Expert", () {
            if (widget.selectedCar != null && widget.selectedProblem != null) {
              widget.onFindExpert();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a car and problem first")));
            }
          }),
        ],
      )
        )

    );
  }

  Widget _dropdownBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.myCars.any((e) => e['vid'].toString() == widget.selectedCar) ? widget.selectedCar : null,
          isExpanded: true,
          hint: const Text("Select your car"),
          items: widget.myCars.map((e) => DropdownMenuItem<String>(
              value: e['vid'].toString(),
              child: Text("${e['make']} ${e['model']} ${e['variant']} (${e['year']})")
          )).toList(),
          onChanged: widget.onCarChanged,
        ),
      ),
    );
  }

  Widget _categorySection(String title, List<String> options, ExpansionTileController controller) => ExpansionTile(
    controller: controller,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    children: options.map((opt) => RadioListTile(
      title: Text(opt),
      value: opt,
      groupValue: widget.selectedProblem, // Yeh ensures hai ke poore page par sirf ek hi select ho
      onChanged: (v) {
        // --- YE WALI LINE ZAROORI HAI ---
        _searchController.text = v.toString();
        widget.onProblemChanged(v.toString());
        // --------------------------------
      },
    )).toList(),
  );

  Widget _filledBtn(String t, VoidCallback f) => ElevatedButton(
    onPressed: f,
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16)),
  );
}