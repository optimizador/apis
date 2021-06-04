# server.rb
require 'sinatra'
require 'pg'
require "sinatra/namespace"
require 'rest-client'

set :bind, '0.0.0.0'
set :port, 8080


get '/' do
    'APIs Optimización'
end

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end
####################################################################
#
# Servicios para dimensionamiento de clúster OCP
#
####################################################################
  get '/sizingclusteroptimo' do
    logger = Logger.new(STDOUT)
    cpu="#{params['cpu']}"
    ram="#{params['ram']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 order by precio asc LIMIT 1"
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



  ####################################################################
  #
  # Servicios para dimensionamiento de blockstorage
  #
  ####################################################################
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

  ####################################################################
  #
  # Servicios para dimensionamiento para PX-backup
  #
  ####################################################################

  get '/volumenrespaldospxbackup' do
    logger = Logger.new(STDOUT)
    almacenamientogb="#{params['almacenamientogb']}"
    #parametros de politicas
    rsemanal="#{params['rsemanal']}"
    rsemanalretencion="#{params['rsemanalretencion']}" #cantidad de backups retenidos
    rdiario="#{params['rdiario']}"
    rdiarioretencion="#{params['rdiarioretencion']}"#cantidad de backups retenidos
    rmensual="#{params['rmensual']}"
    rmensualretencion="#{params['rmensualretencion']}"#cantidad de backups retenidos
    rmensual="#{params['ranual']}"
    rmensualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    ranual="#{params['ranual']}"
    ranualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    ratiocompresion=2.5 #algoritmo de compresion LZ77
    volumentotal=0
    volumentotalcomprimido=0
    resultado=[]
    begin
      logger.info("calculando almacenamiento")
      if rsemanal == true then
        vol=almacenamientogb.to_f*rsemanalretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rdiario == true then
        vol=almacenamientogb.to_f*rdiarioretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rmensual == true then
        vol=almacenamientogb.to_f*rmensualretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if ranual == true then
        vol=almacenamientogb.to_f*ranualretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      volumentotalcomprimido=volumentotal/ratiocompresion
      resultado={ volumentotalgb: volumentotal, volumentotalcomprimidogb: volumentotalcomprimido}
    rescue PG::Error => e
      logger.info(e.message.to_s)
    end
    resultado.to_json
  end

  get '/pxbackupprecio' do
    logger = Logger.new(STDOUT)
    workers="#{params['workers']}"
    resultado=[]
    precio=0
    begin
      logger.info("calculando precio px-backup")
      precio=workers.to_i*0.2*720
      logger.info("precio"+precio.round(2).to_s)
      resultado={ workers: workers, precio: precio.round(2).to_s}
    rescue PG::Error => e
      logger.info(e.message.to_s)
    end
    resultado.to_json
  end

    ####################################################################
    #
    # Servicios para dimensionamiento de IKS
    #
    ####################################################################
  get '/ikssizingclusteroptimo' do
    logger = Logger.new(STDOUT)
    cpu="#{params['cpu']}"
    ram="#{params['ram']}"
    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price precio from public.iks_classic_flavors where infra_type='#{infra_type}' and region='#{region}' order by precio asc LIMIT 1"
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

  get '/ikspreciocluster' do
    logger = Logger.new(STDOUT)
    wn="#{params['wn']}"
    flavor="#{params['flavor']}"
    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type,#{params['wn']} as workers, #{params['wn']}*price precio,region from public.iks_classic_flavors where infra_type='#{infra_type}' and region='#{region}' and flavor='#{flavor}' order by precio asc LIMIT 1"
      t_messages.each do |s_message|
          resultado.push({ flavor: s_message['flavor'], infra_type: s_message['infra_type'], workers: s_message['workers'], precio: s_message['precio'], region: s_message['region'] })
      end
      logger.info(resultado.to_s)
    rescue PG::Error => e
      logger.info(e.message.to_s)
    ensure
      connection.close if connection
    end
    resultado.to_json
  end

  #tamanoiks=2
  #flavoriks="4x16"


      ####################################################################
      #
      # Servicios para dimensionamiento de COS
      #
      ####################################################################
      get '/cospricing' do
        logger = Logger.new(STDOUT)

        country = "#{params['country']}"
        service_type ="#{params['type']}"
        region ="#{params['region']}"
        resiliency ="#{params['resiliency']}"
        storage="#{params['storage']}".to_i #Unidades en GB
        retrival="#{params['retrival']}".to_i #Unidades en GB
        publicoutbound="#{params['publicoutbound']}".to_i #Unidades en GB
        storage_type=""
        opa  ="#{params['opa']}".to_i
        opb  ="#{params['opb']}".to_i
        price_operation_month = 0
        price_storage_month =0
        resultado={}
        if (service_type != 'smart') then
          if (storage.to_i<=(500*1024-1)) then
            storage_type  ="0-499TB"
          else
            storage_type  ="+500TB"
          end
        else
          if ((opa+opb)>=1000*(storage-retrival)) then
            storage_type  ="hot"
          elsif ((opa+opb)<=1*(storage-retrival)) then
            storage_type  ="cold"
          else
            storage_type  ="cool"
          end
        end


        resultado1={}
        logger.info("Query: " +"SELECT price_storage_month*#{storage} precio FROM public.cos_storage_pricing  WHERE country_offer='#{country}' and region='#{region}' and service_type='#{service_type}' and storage_type='#{storage_type}' order by precio asc LIMIT 1")
        begin

          connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
          t_messages = connection.exec "SELECT price_storage_month*#{storage} precio FROM public.cos_storage_pricing WHERE country_offer='#{country}' and region='#{region}' and service_type='#{service_type}' and storage_type='#{storage_type}' order by precio asc LIMIT 1"
          t_messages.each do |s_message|
            resultado1= s_message['precio'].to_f
            logger.info("precio: "+resultado1.to_s)
          end
          logger.info(resultado.to_s)
        rescue PG::Error => e
          logger.info(e.message.to_s)
        ensure
          connection.close if connection
        end

        resultado2={}

        begin

          if (service_type != 'smart') then
            if (storage.to_i<=(500*1024-1)) then
              storage_type  ="0-499TB"
            else
              storage_type  ="+500TB"
            end
          else
            if ((opa+opb)>=1000*(storage-retrival)) then
              storage_type  ="hot"
            elsif ((opa+opb)<=1*(storage-retrival)) then
              storage_type  ="cold"
            else
              storage_type  ="cool"
            end
          end

          logger.info("Query: " +"SELECT (a_pricing*(#{opa}/1000) + b_pricing*(#{opb}/10000) + data_retrival_pricing*#{retrival}) precio FROM public.cos_operational_request_pricing where country_offer='#{country}' and service_type='#{service_type}' and region='#{region}'  and resiliency='#{resiliency}' LIMIT 1")
          connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
          t_messages = connection.exec "SELECT (a_pricing*(#{opa}/1000) + b_pricing*(#{opb}/10000) + data_retrival_pricing*#{retrival}) precio FROM public.cos_operational_request_pricing where country_offer='#{country}' and service_type='#{service_type}' and region='#{region}'  and resiliency='#{resiliency}' LIMIT 1"
          t_messages.each do |s_message|
            resultado2= s_message['precio'].to_f
            logger.info("precio: "+resultado2.to_s)
          end
          logger.info(resultado.to_s)
        rescue PG::Error => e
          logger.info(e.message.to_s)
        ensure
          connection.close if connection
        end


        resultado3={}

        begin
          outboundlimittb=50

                    if (publicoutbound/1024 >=0 && publicoutbound/1024<=50) then
                      outboundlimittb=50
                    elsif (publicoutbound/1024 >50 && publicoutbound/1024<=150)
                      outboundlimittb=150
                    else
                      outboundlimittb=500
                    end

          logger.info("Query: " +"SELECT outboundprice*#{publicoutbound} precio FROM public.cos_public_outbound_bandwidth_pricing WHERE country_offer='#{country}' and service_type='#{service_type}' and region='#{region}' and resiliency='#{resiliency}' and outboundlimittb=#{outboundlimittb}")

          connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
          t_messages = connection.exec "SELECT outboundprice*#{publicoutbound} precio FROM public.cos_public_outbound_bandwidth_pricing WHERE country_offer='#{country}' and service_type='#{service_type}' and region='#{region}' and resiliency='#{resiliency}' and outboundlimittb=#{outboundlimittb}"
          t_messages.each do |s_message|
            resultado3=s_message['precio'].to_f
            logger.info("precio: "+resultado3.to_s)
          end
          logger.info(resultado.to_s)
        rescue PG::Error => e
          logger.info(e.message.to_s)
        ensure
          connection.close if connection
        end
        resultado={precio: resultado1+resultado2+resultado3, "nota": "El precio para algunos escenarios puede varias 10%, valida en cloud.ibm.com"}
        logger.info("precio: "+resultado.to_s)
        resultado.to_json
      end
end
