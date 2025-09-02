import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:letterai_colletion/Profile/support/daily_goal_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letterai_colletion/Profile/support/daily_goal_support.dart';
import 'package:numberpicker/numberpicker.dart';

class DailyGoalPage extends StatefulWidget {
  @override
  _DailyGoalPageState createState() => _DailyGoalPageState();
}

class _DailyGoalPageState extends State<DailyGoalPage> {
  final _formKey = GlobalKey<FormState>();

  //Informações pessoais
  final TextEditingController dataController = TextEditingController();
  int altura = 170; // cm
  double peso = 70.0;
  int genero = 0;
  DateTime? dataNascimento;

  //Metas diárias
  int passos = 0;
  int calorias = 0;
  double distancia = 0.0;
  double exercicios = 0.0;
  double sono = 0.0;

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  //Função que carrega os dados
  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final metas = await carregarDadosPessoais(userId);

    setState(() {
      altura = metas.altura.toInt(); // assume que já vem em cm
      peso = metas.peso;

      if (metas.dataNascimento.year > 1900) {
        dataNascimento = metas.dataNascimento;
        dataController.text =
            "${metas.dataNascimento.day.toString().padLeft(2, '0')}/${metas.dataNascimento.month.toString().padLeft(2, '0')}/${metas.dataNascimento.year}";
      }

      genero = metas.genero;

      passos = metas.metaPassos;
      calorias = metas.metaCalorias;
      distancia = metas.metaDistancia;
      exercicios = metas.metaExercicios;
      sono = metas.metaSono;

      carregando = false;
    });
  }

  //Função que salva os dados
  void _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('O usuário não está logado');
      return;
    }

    String userId = user.uid;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('estatisticas')
          .doc('dados_pessoais')
          .set({
            'altura': altura.toDouble(),
            'peso': peso,
            'dataNascimento': dataNascimento?.toIso8601String() ?? '',
            'genero': genero,
            'metaPassos': passos,
            'metaCalorias': calorias,
            'metaExercicios': exercicios,
            'metaSono': sono,
            'metaDistancia': distancia,
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dados salvos com sucesso')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar os dados: $e')));
    }
  }

  //Altura

  @override
  Widget build(BuildContext context) {
    double campoWidth = MediaQuery.of(context).size.width * 0.9;
    double espacamento = 16.0;

    if (carregando) {
      return Scaffold(
        appBar: AppBar(title: Text("Dados pessoais")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Dados pessoais')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(espacamento),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(thickness: 1),
              SizedBox(height: espacamento * 0.5),
              //Título das metas
              Text(
                'Seus dados pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: espacamento),

              //Altura
              Text('Altura (cm)', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  int tempAltura = altura; // variável temporária

                  int? newAltura = await showDialog<int>(
                    context: context,
                    builder:
                        (_) => StatefulBuilder(
                          builder:
                              (context, setStateDialog) => AlertDialog(
                                title: Text('Selecione a altura'),
                                content: NumberPicker(
                                  minValue: 1,
                                  maxValue: 250,
                                  value: tempAltura,
                                  onChanged:
                                      (value) => setStateDialog(
                                        () => tempAltura = value,
                                      ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () =>
                                            Navigator.pop(context, tempAltura),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                        ),
                  );

                  if (newAltura != null) {
                    setState(() => altura = newAltura);
                  }
                },
                child: Text('$altura cm'),
              ),

              SizedBox(height: espacamento),

              //Peso
              Text('Peso (kg)', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  double tempPeso = peso; // variável temporária

                  double? newPeso = await showDialog<double>(
                    context: context,
                    builder:
                        (_) => StatefulBuilder(
                          builder:
                              (context, setStateDialog) => AlertDialog(
                                title: Text('Selecione o peso'),
                                content: DecimalNumberPicker(
                                  minValue: 30,
                                  maxValue: 350,
                                  decimalPlaces: 2,
                                  value: tempPeso,
                                  onChanged:
                                      (val) =>
                                          setStateDialog(() => tempPeso = val),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, tempPeso),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                        ),
                  );

                  if (newPeso != null) {
                    setState(() => peso = newPeso); // atualiza o estado da tela
                  }
                },
                child: Text('${peso.toStringAsFixed(2)} kg'),
              ),
              SizedBox(height: espacamento),

              //Data nascimento
              _buildDataNascimentoField(campoWidth),
              SizedBox(height: espacamento),

              //Gênero
              _buildGeneroField(campoWidth),

              SizedBox(height: espacamento * 1),
              Divider(thickness: 1),
              SizedBox(height: espacamento * 0.5),

              //Título das metas
              Text(
                'Suas metas diárias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: espacamento),

              _buildMetaField(
                'Passos',
                passos.toString(),
                500,
                isDouble: false,
                min: 0,
                onChanged: (val) => setState(() => passos = val),
              ),
              SizedBox(height: espacamento),
              _buildMetaField(
                'Calorias',
                calorias.toString(),
                50,
                isDouble: false,
                min: 0,
                onChanged: (val) => setState(() => calorias = val),
              ),
              SizedBox(height: espacamento),
              _buildMetaField(
                'Distancia',
                distancia.toInt().toString(), // evita o ".0"
                500,
                isDouble: false,
                min: 0,
                onChanged: (val) => setState(() => distancia = val.toDouble()),
              ),
              SizedBox(height: espacamento),
              _buildMetaField(
                'Exercício (h)',
                exercicios.toStringAsFixed(1),
                0.5,
                isDouble: true,
                min: 0,
                onChanged: (val) => setState(() => exercicios = val),
              ),
              SizedBox(height: espacamento),
              _buildMetaField(
                'Sono (h)',
                sono.toStringAsFixed(1),
                1.0,
                isDouble: true,
                min: 0,
                onChanged: (val) => setState(() => sono = val),
              ),
              SizedBox(height: espacamento * 2),

              Center(
                child: ElevatedButton(
                  onPressed: _salvarDados,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 12.0,
                    ),
                    child: Text('Salvar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Campos pessoais

  //Data nascimento
  Widget _buildDataNascimentoField(double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: dataController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Data de Nascimento',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: dataNascimento ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              dataNascimento = picked;
              dataController.text =
                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
            });
          }
        },
      ),
    );
  }

  Widget _buildGeneroField(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        value: genero,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Gênero',
        ),
        items: [
          DropdownMenuItem(value: 0, child: Text('Masculino')),
          DropdownMenuItem(value: 1, child: Text('Feminino')),
          DropdownMenuItem(value: 2, child: Text('Outro')),
        ],
        onChanged: (value) {
          setState(() {
            genero = value!;
          });
        },
      ),
    );
  }

  //Metas diárias
  Widget _buildMetaField(
    String label,
    String value,
    double incremento, {
    required bool isDouble,
    double min = 0,
    required Function(dynamic) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
        IconButton(
          onPressed: () {
            if (isDouble) {
              double newValue = double.parse(value) - incremento;
              if (newValue >= min) onChanged(newValue);
            } else {
              int newValue = int.parse(value) - incremento.toInt();
              if (newValue >= min) onChanged(newValue);
            }
          },
          icon: Icon(Icons.remove_circle_outline),
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () {
            if (isDouble) {
              double newValue = double.parse(value) + incremento;
              onChanged(newValue);
            } else {
              int newValue = int.parse(value) + incremento.toInt();
              onChanged(newValue);
            }
          },
          icon: Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
