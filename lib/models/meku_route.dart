class MekuRoute {
  final String destination;
  final Map<String, dynamic> arguments;
  const MekuRoute(this.destination, [this.arguments = const {}]);
}

typedef MekuRouteHandler = bool Function(MekuRoute route);
