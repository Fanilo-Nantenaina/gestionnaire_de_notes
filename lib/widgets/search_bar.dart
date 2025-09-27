import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String hintText;

  const SearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Rechercher dans vos notes...',
  });

  @override
  State<SearchBar> createState() => _SearchBarrState();
}

class _SearchBarrState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSearching = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                widget.onSearchChanged(value);
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              onTap: () {
                _animationController.forward();
                setState(() {
                  _isFocused = true;
                });
              },
              onTapOutside: (_) {
                _animationController.reverse();
                setState(() {
                  _isFocused = false;
                });
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: _isFocused || _isSearching
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400],
                    size: 20,
                  ),
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                    setState(() {
                      _isSearching = false;
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
