import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:provider/provider.dart';

import 'signaling.dart';

//arquivo que contém o código da interface

class CallScreen extends StatelessWidget {
  //classe inicializa a tela do programa
  final String ip; //registra ip

  const CallScreen({Key key, @required this.ip})
      : super(key: key); //informações para tela do usuário

  @override
  Widget build(BuildContext context) {
    //inicializa a tela pela chamada dos contrutores passando o ip
    return ChangeNotifierProvider(
      create: (_) => CallProvider(),
      child: CallBody(ip: ip),
    );
  }
}

class CallBody extends StatefulWidget {
  //classe de dados da chamada
  static String tag = 'call_sample';

  final String ip;

  CallBody({Key key, @required this.ip}) : super(key: key);

  @override
  _CallBodyState createState() => _CallBodyState(serverIP: ip);
}

class _CallBodyState extends State<CallBody> {
  //gerencia as funcionalidades apresentadas na tela
  Signaling _signaling;
  var _selfId; //id da chamada
  RTCVideoRenderer _localRenderer =
      RTCVideoRenderer(); //reponsável pelo vídeo local
  RTCVideoRenderer _remoteRenderer =
      RTCVideoRenderer(); //responsável pelo vídeo remoto
  bool _inCalling = false; //informa se há chamada em andamento
  final String serverIP; //ip do servidor
  final TextEditingController textEditingController = TextEditingController();
  int indexTab = 0;

  _CallBodyState({Key key, @required this.serverIP});

  @override
  initState() {
    //inicializa a chamada, chamando os metodos necessários para tal
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    //inicializa as variaveis responsávies pelo video
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    //encerra a chamada
    super.deactivate();
    if (_signaling != null) _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    //gerencia estado da chamada
    if (_signaling == null) {
      _signaling = Signaling(serverIP)..connect();

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew: //informa inicialização da chamada
            this.setState(() {
              _inCalling = true;
            });
            break;
          case SignalingState.CallStateBye: //informa finalização da chamada
            this.setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _inCalling = false;
            });
            break;
          //não alteram o estado da chamada
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };

      _signaling.onEventUpdate = ((event) {
        final clientId = event['clientId'];
        context.read<CallProvider>().updateClientIp(clientId);
        //atualiza o id do usuário responsável pela chamada
      });

      _signaling.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
        });
      });

      _signaling.onLocalStream = ((stream) {
        //video local
        _localRenderer.srcObject = stream;
      });

      _signaling.onAddRemoteStream = ((stream) {
        //recebendo video remoto
        _remoteRenderer.srcObject = stream;
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        //não recebe video remoto
        _remoteRenderer.srcObject = null;
      });
    }
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'video', useScreen);
      //verifica condições para o convite
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling.bye();
      //informa final da chamada
    }
  }

  _switchCamera() {
    _signaling.switchCamera();
    //troca camera
  }

  _muteMic() {} //muta o microfone

  @override
  Widget build(BuildContext context) {
    //código da interface da aplicação
    return MaterialApp(
        home: DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                    title: Consumer<CallProvider>(
                      builder: (context, provider, child) {
                        final clientId = provider.clientId;
                        return clientId.isNotEmpty
                            ? Text('$clientId')
                            : Text('P2P Call Sample');
                      },
                    ),
                    actions: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: null,
                        tooltip: 'setup',
                      ),
                    ],
                    bottom: TabBar(
                      onTap: (index) {
                        setState(() {
                          indexTab = index;
                        });
                      },
                      tabs: [
                        Tab(text: "Câmera"),
                        Tab(text: "Stream"),
                      ],
                    )),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
                floatingActionButton: _inCalling
                    ? SizedBox(
                        width: 200.0,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              FloatingActionButton(
                                child: const Icon(Icons.switch_camera),
                                onPressed: _switchCamera,
                              ),
                              FloatingActionButton(
                                onPressed: _hangUp,
                                tooltip: 'Hangup',
                                child: Icon(Icons.call_end),
                                backgroundColor: Colors.pink,
                              ),
                              FloatingActionButton(
                                child: const Icon(Icons.mic_off),
                                onPressed: _muteMic,
                              )
                            ]))
                    : null,
                body: TabBarView(children: [
                  _inCalling
                      ? OrientationBuilder(builder: (context, orientation) {
                          return Container(
                            child: Positioned(
                                left: 0.0,
                                right: 0.0,
                                top: 0.0,
                                bottom: 0.0,
                                child: Container(
                                  margin:
                                      EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  child: RTCVideoView(_localRenderer),
                                  decoration:
                                      BoxDecoration(color: Colors.black54),
                                )),
                          );
                        })
                      : Container(
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              TextField(
                                controller: textEditingController,
                              ),
                              FlatButton(
                                child: Text('Call'),
                                color: Colors.green,
                                onPressed: () {
                                  _invitePeer(context,
                                      textEditingController.text, false);
                                },
                              )
                            ],
                          ),
                        ),
                  _inCalling
                      ? OrientationBuilder(builder: (context, orientation) {
                          return Container(
                            child: Positioned(
                                left: 0.0,
                                right: 0.0,
                                top: 0.0,
                                bottom: 0.0,
                                child: Container(
                                  margin:
                                      EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  child: RTCVideoView(_remoteRenderer),
                                  decoration:
                                      BoxDecoration(color: Colors.black54),
                                )),
                          );
                        })
                      : Container(
                          color: Colors.blue[50],
                          child: Column(
                            children: <Widget>[
                              TextField(
                                controller: textEditingController,
                              ),
                              FlatButton(
                                child: Text('Call'),
                                color: Colors.green,
                                onPressed: () {
                                  _invitePeer(context,
                                      textEditingController.text, false);
                                },
                              )
                            ],
                          ),
                        ),
                ]))));
  }
}

class CallProvider with ChangeNotifier {
  String clientId = "";

  void updateClientIp(String newClientId) {
    //informa novo id do cliente resonsável pela chamada
    clientId = newClientId;
    notifyListeners();
  }
}
