import 'package:flutter/material.dart';

class ProgressBars extends StatelessWidget {
  final String imagem;
  final int valorAtual;
  final int meta;
  final Color corBarra;

  const ProgressBars({
    super.key,
    required this.imagem,
    required this.valorAtual,
    required this.meta,
    required this.corBarra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            children: [
              Image.asset(imagem, width: 32, height: 32),
              const SizedBox(height: 10),
              Text(
                '$valorAtual',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      value: valorAtual / meta,
                      valueColor: AlwaysStoppedAnimation<Color>(corBarra),
                      backgroundColor: Colors.grey[300],
                      minHeight: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                //Meta alinhada à direita
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$meta',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
