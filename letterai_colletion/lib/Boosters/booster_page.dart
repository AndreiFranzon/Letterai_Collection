import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:letterai_colletion/Boosters/sorting_function.dart';
import 'package:letterai_colletion/Models/pacote.dart';

class BoosterPage extends StatefulWidget {
  final Pacote pacote;
  final bool decrementarInventario;

  const BoosterPage({
    super.key,
    required this.pacote,
    required this.decrementarInventario,
  });

  @override
  State<BoosterPage> createState() => _BoosterPageState();
}

class _BoosterPageState extends State<BoosterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late ConfettiController _confettiController;

  bool pacoteAberto = false;
  bool mostrarCartas = false;

  List<Map<String, dynamic>> cartas = [];
  Map<String, dynamic>? energia;

  int topIndex = 0; // controle de qual carta/energia está visível no topo
  double cartaOffsetX = 0; // deslocamento horizontal da carta sendo clicada

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          mostrarCartas = true; // mostra pilha de cartas depois da animação
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _abrirPacote() async {
    if (pacoteAberto) return;

    pacoteAberto = true;

    await precacheImage(AssetImage(widget.pacote.imagem), context);

    final resultado = await abrirPacote(
      pacote: widget.pacote,
      decrementarInventario: widget.decrementarInventario,
    );

    setState(() {
      cartas = resultado['cartas'] as List<Map<String, dynamic>>;
      energia = resultado['energia'] as Map<String, dynamic>?;
      topIndex = 0;
    });

    _controller.forward();
    _confettiController.play();
  }

  void _clicarItem() {
    setState(() {
      if (topIndex < cartas.length) {
        // animação da carta saindo para a direita
        cartaOffsetX = MediaQuery.of(context).size.width;
        Future.delayed(const Duration(milliseconds: 300), () {
          // depois da animação, remove a carta
          setState(() {
            cartaOffsetX = 0;
            topIndex++;
          });
        });
      } else {
        // energia: fecha a tela
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = cartas.length + (energia != null ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true, // já coloca a seta de voltar
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      extendBodyBehindAppBar: true, // faz o corpo "subir" por trás da appbar
  
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Luz central
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder:
                  (_, child) => Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
            ),

            // Pacote que cresce e some
            if (!mostrarCartas)
              GestureDetector(
                onTap: _abrirPacote,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder:
                      (_, child) => Opacity(
                        opacity: 1 - _opacityAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Image.asset(
                            widget.pacote.imagem,
                            width: 250,
                            height: 450,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                ),
              ),

            // Confetes
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.yellow,
                Colors.green,
                Colors.purple,
              ],
              gravity: 0.3,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 30,
              minBlastForce: 20,
            ),

            // Pilha de cartas + energia
            if (mostrarCartas && topIndex < totalItems)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Energia no fundo da pilha
                  if (energia != null)
                    Image.asset(
                      'assets/energies/${energia!['energiaId']}.png',
                      width: 280,
                      height: 420,
                    ),

                  // Cartas empilhadas
                  ...List.generate(cartas.length, (i) {
                    final index = cartas.length - 1 - i;
                    if (index < topIndex) return const SizedBox();
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      left: index == topIndex ? cartaOffsetX : 0,
                      child: GestureDetector(
                        onTap: _clicarItem,
                        child: Image.asset(
                          cartas[i]['imagem'],
                          width: 280,
                          height: 420,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }),

                  // Mostrar quantidade de energia só quando energia estiver visível
                  if (energia != null && topIndex > cartas.length - 1)
                    Positioned(
                      bottom: 20,
                      child: GestureDetector(
                        onTap: _clicarItem,
                        child: Column(
                          children: [
                            Text(
                              "+${energia!['quantidade']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
