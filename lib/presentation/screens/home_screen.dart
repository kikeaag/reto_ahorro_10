import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const savedTotal = 145.0;
    const goal = 300.0;
    final percent = ((savedTotal / goal) * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reto de dinero'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('145 / 300'),
                Text('${percent.toStringAsFixed(2)} %')
              ],
            ),
            Text("Total: \$750"),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Ver más'),
                  ),
              ],
            ),
            SizedBox(height: 20),
            Text('10'),
            SizedBox(height: 10,),
            Expanded(
              child: GridView.count(
                primary: false,
                crossAxisSpacing: 10,
                mainAxisSpacing: 5,
                crossAxisCount: 5,
                children: [
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('10'),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(child: const Text("10")),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(child: const Text("10")),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}