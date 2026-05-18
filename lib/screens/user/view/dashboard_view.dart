
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> myCars;
  final List<Map<String, dynamic>> allProblems;
  final String? selectedCar;
  final String? selectedProblem;
  final String userName;
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
    required this.userName,
    required this.onCarChanged,
    required this.onProblemChanged,
    required this.onFindExpert,
    required this.onRefresh,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _searchController = TextEditingController();

  final ExpansionTileController _headlightCtrl = ExpansionTileController();
  final ExpansionTileController _hornCtrl = ExpansionTileController();
  final ExpansionTileController _indicatorCtrl = ExpansionTileController();

  void _showProblemSearchModal(BuildContext context) {
    List<Map<String, dynamic>> filteredProblems = List.from(widget.allProblems);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Search Problem", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search e.g. Headlight, Horn...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filteredProblems = widget.allProblems
                            .where((p) => p['ptitle'].toString().toLowerCase().contains(val.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: filteredProblems.isEmpty
                        ? const Center(child: Text("No problem found"))
                        : ListView.builder(
                      itemCount: filteredProblems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          //leading: const Icon(Icons.build_circle_outlined),
                          title: Text(filteredProblems[index]['ptitle']),
                          onTap: () {
                            _handleSearchSelection(filteredProblems[index]['ptitle']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleSearchSelection(String pTitle) {
    widget.onProblemChanged(pTitle);
    setState(() {
      _searchController.text = pTitle;
    });

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
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1B2E4B),
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- WELCOME SECTION ---
            // const Text("Welcome", style: TextStyle(fontSize: 14, color: Colors.grey)),
            // Text(
            //     widget.userName, // <--- Parent se aya hua naam yahan show hoga
            //     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B2E4B))
            // ),
            const SizedBox(height: 25),

            const Text("Select Your Car", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),
            _dropdownBox(),

            const SizedBox(height: 25),
            const Text("Select Problem", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),

            GestureDetector(
              onTap: () => _showProblemSearchModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.selectedProblem ?? "Click to search problem...",
                        style: TextStyle(
                          color: widget.selectedProblem == null ? Colors.grey : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF1B2E4B), size: 30),
                  ],
                ),
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
        ),
      ),
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
      groupValue: widget.selectedProblem,
      activeColor: const Color(0xFF1B2E4B),
      onChanged: (v) {
        setState(() {
          widget.onProblemChanged(v.toString());
        });
      },
    )).toList(),
  );

  Widget _filledBtn(String t, VoidCallback f) => ElevatedButton(
    onPressed: f,
    style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B2E4B),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
    ),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16)),
  );
}