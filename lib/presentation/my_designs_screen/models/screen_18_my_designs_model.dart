import 'package:equatable/equatable.dart';
import 'playlist_item_model.dart';

class Screen18MyDesignsModel extends Equatable {
  Screen18MyDesignsModel({this.playlistItemList = const []});
  final List<PlaylistItemModel> playlistItemList;
  Screen18MyDesignsModel copyWith({List<PlaylistItemModel>? playlistItemList}) {
    return Screen18MyDesignsModel(
      playlistItemList: playlistItemList ?? this.playlistItemList,
    );
  }

  @override
  List<Object?> get props => [playlistItemList];
}
