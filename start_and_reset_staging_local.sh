echo "Stopping Containers"
docker-compose -f docker-compose.staging_local.yml down

echo "Set environment"
docker-compose -f docker-compose.staging_local.yml run --rm api ruby bin/rails db:environment:set RAILS_ENV=staging_local

echo "Drop the database"
docker-compose -f docker-compose.staging_local.yml run --rm api ruby bin/rails db:drop db:create db:migrate db:seed RAILS_ENV=staging_local

echo "Preprocess personal images"
docker-compose -f docker-compose.staging_local.yml run --rm api ruby bin/rails airett:preprocess_personal_images RAILS_ENV=staging_local

echo "Starting Container"
docker-compose -f docker-compose.staging_local.yml up
