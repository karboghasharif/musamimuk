import '../models/design_persistence_models.dart';
import '../repositories/design_repository.dart';

sealed class PrepareRedesignResult {}

class PrepareRedesignSuccess extends PrepareRedesignResult {
  PrepareRedesignSuccess(this.design);
  final RedesignDesign design;
}

class PrepareRedesignFailure extends PrepareRedesignResult {
  PrepareRedesignFailure(this.message);
  final String message;
}

/// Coordinates clone-then-load without ever reopening the source design ID.
class DesignRedesignService {
  DesignRedesignService({DesignRepository? repository})
    : _repository = repository ?? DesignRepository();

  final DesignRepository _repository;

  Future<PrepareRedesignResult> prepare({
    required int sourceDesignId,
    required bool cloneBeforeOpening,
  }) async {
    var targetDesignId = sourceDesignId;
    if (cloneBeforeOpening) {
      final cloneResult = await _repository.clone(sourceDesignId);
      switch (cloneResult) {
        case DesignCloneSuccess(:final design):
          targetDesignId = design.id;
        case DesignCloneFailure(:final message):
          return PrepareRedesignFailure(message);
      }
    }

    final redesignResult = await _repository.loadForRedesign(targetDesignId);
    return switch (redesignResult) {
      DesignRedesignSuccess(:final design) => PrepareRedesignSuccess(design),
      DesignRedesignFailure(:final message) => PrepareRedesignFailure(message),
    };
  }
}
