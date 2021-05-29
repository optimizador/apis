# server.rb
require 'sinatra'
require 'pg'
require "sinatra/namespace"


set :bind, '0.0.0.0'
set :port, 8080


get '/' do
    'APIs Optimización'
end

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  get '/sizingcluster' do
    logger = Logger.new(STDOUT)
    cpu="#{params['cpu']}"
    ram="#{params['ram']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 order by precio asc"
      t_messages.each do |s_message|
          resultado.push({ flavor: s_message['flavor'], infra_type: s_message['infra_type'], workers: s_message['workers'], precio: s_message['precio'], precio_subs: s_message['precio_subs'] })
      end
      logger.info(resultado.to_s)
    rescue PG::Error => e
      logger.info(e.message.to_s)
    ensure
      connection.close if connection
    end
    resultado.to_json
  end

  get '/sizingblockstorage' do
    logger = Logger.new(STDOUT)
    iops="#{params['iops']}"
    region="#{params['region']}"
    storage="#{params['storage']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select b.iops,b.maxunit,u.unidades, (u.unidades*b.maxunit*b.pricegb) precio, u.unidadrestante,(u.unidadrestante*b.pricegb) preciounidadrestante from (select iops, region, floor(#{storage}/maxunit) as unidades, ceil((#{storage}/maxunit-floor(#{storage}/maxunit))*maxunit) unidadrestante from public.blockstorage) u INNER JOIN public.blockstorage b ON b.iops = u.iops and u.region=b.region where b.iops='#{iops}' and b.region='#{region}'"
      #t_messages = connection.exec "select ceil(#{storage}/maxunit) unidades, ceil(#{storage}/maxunit)*pricegb precio, #{storage}*pricegb precioexacto from public.blockstorage where iops=#{iops} and region=#{region}"
      t_messages.each do |s_message|
          resultado.push({ iops: s_message['iops'],maxunit: s_message['maxunit'], unidades: s_message['unidades'], precio: s_message['precio'], unidadrestante: s_message['unidadrestante'], preciounidadrestante: s_message['preciounidadrestante'] })
      end
      logger.info(resultado.to_s)
    rescue PG::Error => e
      logger.info(e.message.to_s)
    ensure
      connection.close if connection
    end
    resultado.to_json
  end
end
