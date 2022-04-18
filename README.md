# pbl_sd
### Configurador de porta serial - Raspberry pi Zero

O projeto foi desenvolvido em assembly com o objetivo de configurar a porta serial (UART) de uma placa raspberry pi zero.

#### Configurações possíveis
- Paridade
- Velocidade (baud rate)
- Quantidade de bits de parada
- Quantidade de bits de mensagem

Para configurar os parâmetros àcima é necessário modificar as constantes que fazem referência aos valores desejados diretamento no código fonte (uart_setup.s), recompilar o projeto e rodar novamente.

### Estruturação de arquivos

-- uart_setup.s
Arquivo principal que contém todo fluxo de configuração da UART, como a inicialização das constantes que fazem referência aos valores dos registradores e configurações, mapeamento do endereço de memória, envio e recebimento dos dados para teste de funcionamento.

-- macros.s
Arquivo que contém macros utilizados para auxiliar no desenvolvimento do projeto, como abrir e fechar arquivo e printar strings

-- gpiomem.s
Arquivo auxiliar que contém código do mapeamento dos pinos da raspberry, este arquivo não está sendo utilizado no fluxo, o código foi retirado do livro.

-- call_system.s
Arquivo que contém as constantes que fazem referência às chamadas do sistema que foram utilizadas no desenvolvimento.
