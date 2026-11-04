part of 'screen_18_my_designs_bloc.dart';

enum MyDesignsVisibilityTab { public, private, local }

class Screen18MyDesignsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsInitialEvent extends Screen18MyDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsLoadEvent extends Screen18MyDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsSearchChangedEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsSearchChangedEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class Screen18MyDesignsVisibilityTabChangedEvent
    extends Screen18MyDesignsEvent {
  Screen18MyDesignsVisibilityTabChangedEvent(this.tab);
  final MyDesignsVisibilityTab tab;
  @override
  List<Object?> get props => [tab];
}

class Screen18MyDesignsDeleteEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsDeleteEvent(this.designId);
  final int designId;
  @override
  List<Object?> get props => [designId];
}

class Screen18MyDesignsDeleteLocalEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsDeleteLocalEvent(this.localId);
  final String localId;
  @override
  List<Object?> get props => [localId];
}

class Screen18MyDesignsSelectFolderEvent extends Screen18MyDesignsEvent {
  /// `null` = All, [DesignFolderStore.unfiledId] = Unfiled, else folder id.
  Screen18MyDesignsSelectFolderEvent(this.folderId);
  final String? folderId;
  @override
  List<Object?> get props => [folderId];
}

class Screen18MyDesignsCreateFolderEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsCreateFolderEvent(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class Screen18MyDesignsRenameFolderEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsRenameFolderEvent({
    required this.folderId,
    required this.name,
  });
  final String folderId;
  final String name;
  @override
  List<Object?> get props => [folderId, name];
}

class Screen18MyDesignsDeleteFolderEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsDeleteFolderEvent(this.folderId);
  final String folderId;
  @override
  List<Object?> get props => [folderId];
}

class Screen18MyDesignsMoveDesignEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsMoveDesignEvent({
    required this.designId,
    required this.isLocal,
    this.folderId,
  });
  final String designId;
  final bool isLocal;
  /// Null / empty = Unfiled.
  final String? folderId;
  @override
  List<Object?> get props => [designId, isLocal, folderId];
}
