# setup docker image config
cp app/models/exchange_information.rb app/models/exchange_information.rb.tmp
cp config/database.rb config/database.rb.tmp
cp Gemfile Gemfile.tmp
cp .docker/config/exchange.yml config/
cp .docker/config/puma.rb config/
cp .docker/config/database.rb config/
cp .docker/config/exchange_information.rb app/models/
cp .docker/config/Gemfile .

docker build --build-arg BUNDLER_VERSION_OVERRIDE='1.17.3' \
             -f .docker/production/Dockerfile --target app -t $2:$1 .
docker push $2:$1

mv app/models/exchange_information.rb.tmp  app/models/exchange_information.rb
mv config/database.rb.tmp config/database.rb
mv Gemfile.tmp Gemfile
rm config/exchange.yml
rm config/puma.rb

