import '../models/task_models.dart';

int prioritySortRank(Priority priority) => switch (priority) {
  Priority.high => 0,
  Priority.medium => 1,
  Priority.low => 2,
};
