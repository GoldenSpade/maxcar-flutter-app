import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vehicle_settings_provider.dart';
import '../../../core/utils/currency_utils.dart';

/// Vehicle settings screen for fuel consumption
class VehicleSettingsScreen extends ConsumerStatefulWidget {
  const VehicleSettingsScreen({super.key});

  @override
  ConsumerState<VehicleSettingsScreen> createState() =>
      _VehicleSettingsScreenState();
}

class _VehicleSettingsScreenState
    extends ConsumerState<VehicleSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _consumptionController;
  late TextEditingController _priceController;
  late String _selectedFuelType;
  late String _selectedCurrency;

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Gas (LPG)',
    'Electric',
  ];

  final Map<String, String> _currencies = {
    'USD': '\$ (USD)',
    'EUR': '€ (EUR)',
    'UAH': '₴ (UAH)',
    'GBP': '£ (GBP)',
    'RUB': '₽ (RUB)',
    'PLN': 'zł (PLN)',
    'JPY': '¥ (JPY)',
    'CNY': '¥ (CNY)',
  };

  @override
  void initState() {
    super.initState();
    final settings = ref.read(vehicleSettingsProvider);
    _consumptionController =
        TextEditingController(text: settings.fuelConsumption.toStringAsFixed(1));
    _priceController =
        TextEditingController(text: settings.fuelPrice.toStringAsFixed(2));
    _selectedFuelType = settings.fuelType;
    _selectedCurrency = settings.currency;
  }

  @override
  void dispose() {
    _consumptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final consumption = double.tryParse(_consumptionController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    try {
      await ref.read(vehicleSettingsProvider.notifier).saveSettings(
            ref.read(vehicleSettingsProvider).copyWith(
                  fuelConsumption: consumption,
                  fuelType: _selectedFuelType,
                  fuelPrice: price,
                  currency: _selectedCurrency,
                ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(vehicleSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSettings,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fuel Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_gas_station,
                            color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Fuel Type',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFuelType,
                      decoration: const InputDecoration(
                        labelText: 'Select fuel type',
                        border: OutlineInputBorder(),
                      ),
                      items: _fuelTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFuelType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fuel Consumption
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Fuel Consumption',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _consumptionController,
                      decoration: const InputDecoration(
                        labelText: 'Liters per 100 km',
                        suffixText: 'L/100km',
                        border: OutlineInputBorder(),
                        helperText: 'Average fuel consumption of your vehicle',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter fuel consumption';
                        }
                        final consumption = double.tryParse(value);
                        if (consumption == null || consumption <= 0) {
                          return 'Please enter a valid number';
                        }
                        if (consumption > 50) {
                          return 'Value seems too high';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fuel Price
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Fuel Price',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price per liter',
                        prefixText:
                            '${CurrencyUtils.getCurrencySymbol(_selectedCurrency)} ',
                        suffixText: 'per L',
                        border: const OutlineInputBorder(),
                        helperText: 'Current fuel price at your location',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter fuel price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Currency
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_exchange,
                            color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Currency',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Select currency',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Example calculation
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Example Calculation',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For a 100 km trip:',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ExampleRow(
                      label: 'Fuel used',
                      value:
                          '${settings.fuelConsumption.toStringAsFixed(1)} L',
                    ),
                    _ExampleRow(
                      label: 'Estimated cost',
                      value: CurrencyUtils.formatPrice(
                          settings.fuelConsumption * settings.fuelPrice,
                          _selectedCurrency),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reset button
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset to Default'),
                    content: const Text(
                        'Are you sure you want to reset to default settings?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  await ref
                      .read(vehicleSettingsProvider.notifier)
                      .resetToDefault();
                  final defaultSettings =
                      ref.read(vehicleSettingsProvider);
                  setState(() {
                    _consumptionController.text =
                        defaultSettings.fuelConsumption.toStringAsFixed(1);
                    _priceController.text =
                        defaultSettings.fuelPrice.toStringAsFixed(2);
                    _selectedFuelType = defaultSettings.fuelType;
                    _selectedCurrency = defaultSettings.currency;
                  });
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Default'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String label;
  final String value;

  const _ExampleRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
