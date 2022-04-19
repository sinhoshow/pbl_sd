# pbl_sd
### Configurador de porta serial - Raspberry pi Zero

O projeto foi desenvolvido em assembly com o objetivo de configurar a porta serial (UART) de uma placa raspberry pi zero.

#### Configurações possíveis
- Paridade
- Velocidade (baud rate)
- Quantidade de bits de parada
- Quantidade de bits de mensagem

Para configurar os parâmetros àcima é necessário modificar as constantes que fazem referência aos valores desejados diretamento no código fonte (uart_setup.s), recompilar o projeto e rodar novamente. [EM que linha tal modificação configura tal coisa]

### Estruturação de arquivos

-- uart_setup.s

Arquivo principal que contém todo fluxo de configuração da UART, como a inicialização das constantes que fazem referência aos valores dos registradores e configurações, mapeamento do endereço de memória, envio e recebimento dos dados para teste de funcionamento.

-- macros.s

Arquivo que contém macros utilizados para auxiliar no desenvolvimento do projeto, como abrir e fechar arquivo e printar strings

-- gpiomem.s

Arquivo auxiliar que contém código do mapeamento dos pinos da raspberry, este arquivo não está sendo utilizado no fluxo, o código foi retirado do livro.

-- call_system.s

Arquivo que contém as constantes que fazem referência às chamadas do sistema que foram utilizadas no desenvolvimento.

-- run.sh

Script para montar o executável e executar o projeto

-- debug.sh

Script para abrir o debug do projeto, para debugar tem-se que escolher um break point, colocando "b" no terminal e a linha do código. Depois coloca-se “r” para rodar o código até o local do break point.

[Diagrama de blocos do projeto]

### Rodando o projeto
O projeto foi desenvolvido para a Raspberry pi Zero, portanto é necessário ter a placa para execução do código. Na versão ARM BCM2835,   
[Especificar ambiente do projeto: versão do arm, sistema operacional da raspberrypi zero]

##### No terminal da placa:

- Clonar o projeto
  `git clone https://github.com/sinhoshow/pbl_sd.git`

- Executar run.sh
  `chmod +x run.sh; ./run.sh`

### Testando envio e recebimento dos dados
Para testar o envio de dados, tem que colocar as garras do osciloscópio na GND da UART e outra no TXRE da UART. Já para fazer o teste de loopback tem-se que fazer um debug no código e  usar a instrução “i r” no terminal para ver os registradores. Ao fazer esses passos, tem-se que observar o R0 para ver se o valor colocado  é o mesmo que está na linha 345. Pois, depois de executado o código ele terá enviado e recebido o dado da linha 345.
