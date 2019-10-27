namespace :deploy do
  desc 'Start the vigilante'
  after :finishing, :start do
    on roles(:all) do
      within current_path do
        execute :bundle, 'exec whenever --clear-crontab'
        execute :bundle, 'exec whenever --update-crontab'
      end
    end
  end
end