resource "aws_ecr_repository" "task-app-repo" {
  name                 = "task-app-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
