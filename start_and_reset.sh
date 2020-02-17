echo "Stopping Containers"
docker-compose down

echo "Set environment"
docker-compose run --rm api bin/rails db:environment:set RAILS_ENV=development_local

echo "Drop the database"
docker-compose run --rm api bin/rails db:drop db:create db:migrate db:seed RAILS_ENV=development_local

echo "Preprocess personal images"
docker-compose run --rm api bin/rails airett:preprocess_personal_images RAILS_ENV=development_local

echo "Starting Container"
docker-compose up
