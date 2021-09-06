# server.rb
require 'sinatra'
require 'pg'
require "sinatra/namespace"
require 'rest-client'
require 'bigdecimal'
require 'bigdecimal/util'

set :bind, '0.0.0.0'
set :port, 8080


get '/' do
    'APIs Optimización'
end


namespace '/api/lvl2' do
  before do
    content_type 'application/json'
  end
  #urlapi="localhost:8080"
  urlapi="https://apis.9sxuen7c9q9.us-south.codeengine.appdomain.cloud"

  get '/pxbackupsol' do
    logger = Logger.new(STDOUT)

    almacenamientogb="#{params['almacenamientogb']}" #cantidad en GB
    #parametros de politicas
    rsemanal="#{params['rsemanal']}"
    rsemanalretencion="#{params['rsemanalretencion']}" #cantidad de backups retenidos
    rdiario="#{params['rdiario']}"
    rdiarioretencion="#{params['rdiarioretencion']}"#cantidad de backups retenidos
    rmensual="#{params['rmensual']}"
    rmensualretencion="#{params['rmensualretencion']}"#cantidad de backups retenidos
    ranual="#{params['ranual']}"
    ranualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    regioncluster="#{params['regioncluster']}"#region del cluster de IKS donde se desplegará PX-Backup
    almacenamientocos=0
    clusteriks={}
    resultado=[]
    almacenamientorespaldos=0
    preciofinal=0
    ##########################
    # Calculo Almacenamiento
    ##########################
    logger.info("********************************")
    logger.info("#{urlapi}/api/v1/volumenrespaldospxbackup?almacenamientogb=#{almacenamientogb}&rsemanal=#{rsemanal}&rsemanalretencion=#{rsemanalretencion}&rdiario=#{rdiario}&rdiarioretencion=#{rdiarioretencion}&rmensual=#{rmensual}&rmensualretencion=#{rmensualretencion}&ranual=#{ranual}&ranualretencion=#{ranualretencion}")
    logger.info("********************************")
    respuestasizing = RestClient.get "#{urlapi}/api/v1/volumenrespaldospxbackup?almacenamientogb=#{almacenamientogb}&rsemanal=#{rsemanal}&rsemanalretencion=#{rsemanalretencion}&rdiario=#{rdiario}&rdiarioretencion=#{rdiarioretencion}&rmensual=#{rmensual}&rmensualretencion=#{rmensualretencion}&ranual=#{ranual}&ranualretencion=#{ranualretencion}", {:params => {}}
    logger.info(respuestasizing.to_s)
    almacenamientocos=JSON.parse(respuestasizing.to_s)
    almacenamientorespaldos=almacenamientocos["volumentotalcomprimidogb"]
    resultado.push(almacenamientocos)

    ##########################
    # Calculo clúster para PX-Backup
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"
    respuestasizing = RestClient.get "#{urlapi}/api/v1/ikspreciocluster?region=#{regioncluster}&wn=#{tamanoiks}&flavor=#{flavoriks}&infra_type=#{infra_type}", {:params => {}}
    clusteriks=JSON.parse(respuestasizing.to_s)
    logger.info("RestClient: " +respuestasizing.to_s);
    logger.info("JSON : "+ clusteriks.to_s);
    preciofinal=preciofinal+clusteriks[0]["precio"]
    resultado.push(clusteriks[0])

    ##########################
    # Calculo precio para PX-Backup
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"
    respuestasizing = RestClient.get "#{urlapi}/api/v1/pxbackupprecio?workers=#{tamanoiks}", {:params => {}}
    pxbackup=JSON.parse(respuestasizing.to_s)
    logger.info("RestClient: " +respuestasizing.to_s);
    logger.info("JSON : "+ pxbackup.to_s);
    preciofinal=preciofinal+pxbackup["precio"]
    resultado.push(pxbackup)

    ##########################
    # Calculo precio COS
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"


    countryrespaldo = "#{params['countryrespaldo']}"
    service_type ="cold vault" #considera que los respaldos son cold vault
    region ="mexico" #considera que el país por defecto es México
    resiliency ="#{params['resiliencybackup']}"
    #storage="#{params['storage']}".to_i #Unidades en GB
    retrival=almacenamientorespaldos*0.05 #Considera 5% de recuperación de respaldos
    publicoutbound=0 #Unidades en GB, sin salida publica de los respaldos
    opa=10000 #valores bajos esperados para un respaldo
    opb=100000 #valores bajos esperados para un respaldo

    respuestasizing = RestClient.get "#{urlapi}/api/v1/cospricing?country=#{countryrespaldo}&region=#{region}&type=#{service_type}&resiliency=#{resiliency}&storage=#{almacenamientorespaldos}&retrival=#{retrival}&opa=#{opa}&opb=#{opb}&publicoutbound=#{publicoutbound}", {:params => {}}
    cospricing=JSON.parse(respuestasizing.to_s)
    preciofinal=preciofinal+cospricing["precio"]
    logger.info("precio calculado: "+preciofinal.to_s)
    resultado.push(cospricing)
    resultado.push({preciototal:preciofinal.round(2)})
    resultado.to_json
  end



  get '/pxbackupsol_pxent' do
    logger = Logger.new(STDOUT)

    almacenamientogb="#{params['almacenamientogb']}" #cantidad en GB
    #parametros de politicas
    rsemanal="#{params['rsemanal']}"
    rsemanalretencion="#{params['rsemanalretencion']}" #cantidad de backups retenidos
    rdiario="#{params['rdiario']}"
    rdiarioretencion="#{params['rdiarioretencion']}"#cantidad de backups retenidos
    rmensual="#{params['rmensual']}"
    rmensualretencion="#{params['rmensualretencion']}"#cantidad de backups retenidos
    ranual="#{params['ranual']}"
    ranualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    diff="#{params['diff']}"#cantidad de backups retenidos
    regioncluster="#{params['regioncluster']}"#region del cluster de IKS donde se desplegará PX-Backup
    almacenamientocos=0
    clusteriks={}
    resultado=[]
    almacenamientorespaldos=0
    preciofinal=0
    ##########################
    # Calculo Almacenamiento
    ##########################
    logger.info("********************************")
    callapi="#{urlapi}/api/v1/volumenrespaldospxbackup_w_pxenterprise?almacenamientogb=#{almacenamientogb}&rsemanal=#{rsemanal}&rsemanalretencion=#{rsemanalretencion}&rdiario=#{rdiario}&rdiarioretencion=#{rdiarioretencion}&rmensual=#{rmensual}&rmensualretencion=#{rmensualretencion}&ranual=#{ranual}&ranualretencion=#{ranualretencion}&diff=#{diff}"
    logger.info(callapi)
    logger.info("********************************")
    respuestasizing = RestClient.get callapi, {:params => {}}
    logger.info(respuestasizing.to_s)
    almacenamientocos=JSON.parse(respuestasizing.to_s)
    almacenamientorespaldos=almacenamientocos["volumentotalcomprimidogb"]
    resultado.push(almacenamientocos)

    ##########################
    # Calculo clúster para PX-Backup
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"
    respuestasizing = RestClient.get "#{urlapi}/api/v1/ikspreciocluster?region=#{regioncluster}&wn=#{tamanoiks}&flavor=#{flavoriks}&infra_type=#{infra_type}", {:params => {}}
    clusteriks=JSON.parse(respuestasizing.to_s)
    logger.info("RestClient: " +respuestasizing.to_s);
    logger.info("JSON : "+ clusteriks.to_s);
    preciofinal=preciofinal+clusteriks[0]["precio"]
    resultado.push(clusteriks[0])

    ##########################
    # Calculo precio para PX-Backup
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"
    respuestasizing = RestClient.get "#{urlapi}/api/v1/pxbackupprecio?workers=#{tamanoiks}", {:params => {}}
    pxbackup=JSON.parse(respuestasizing.to_s)
    logger.info("RestClient: " +respuestasizing.to_s);
    logger.info("JSON : "+ pxbackup.to_s);
    preciofinal=preciofinal+pxbackup["precio"]
    resultado.push(pxbackup)

    ##########################
    # Calculo precio COS
    ##########################
    tamanoiks=2  #de acuerdo a documentación de Portworx debe ser 3, con 2 funciona bien
    flavoriks="4x16" #pruebas realizadas con 4x16, de acuerdo a Portworx debe ser 4x8 y 3 nodos
    infra_type="shared"


    countryrespaldo = "#{params['countryrespaldo']}"
    service_type ="cold vault" #considera que los respaldos son cold vault
    region ="mexico" #considera que el país por defecto es México
    resiliency ="#{params['resiliencybackup']}"
    #storage="#{params['storage']}".to_i #Unidades en GB
    retrival=almacenamientorespaldos*0.05 #Considera 5% de recuperación de respaldos
    publicoutbound=0 #Unidades en GB, sin salida publica de los respaldos
    opa=10000 #valores bajos esperados para un respaldo
    opb=100000 #valores bajos esperados para un respaldo

    respuestasizing = RestClient.get "#{urlapi}/api/v1/cospricing?country=#{countryrespaldo}&region=#{region}&type=#{service_type}&resiliency=#{resiliency}&storage=#{almacenamientorespaldos}&retrival=#{retrival}&opa=#{opa}&opb=#{opb}&publicoutbound=#{publicoutbound}", {:params => {}}
    cospricing=JSON.parse(respuestasizing.to_s)
    preciofinal=preciofinal+cospricing["precio"]
    logger.info("precio calculado: "+preciofinal.to_s)
    resultado.push(cospricing)
    resultado.push({preciototal:preciofinal.round(2)})
    resultado.to_json
  end

end


namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

####################################################################
#
# Servicios para dimensionamiento de Soporte
#
####################################################################
  get '/sizingsupport' do
      logger = Logger.new(STDOUT)
      type="#{params['type']}"
      precioservicios="#{params['precioservicios']}".to_f
      preciosoporte=0
      resultado=[]
      begin
        if type=="advanced"
          if precioservicios<2000
            preciosoporte=200
          end
          if precioservicios>=2000 and precioservicios <10000
            preciosoporte=precioservicios*0.06
          end
          if precioservicios>=10000 and precioservicios <100000
            preciosoporte=precioservicios*0.04
          end
          if precioservicios>=100000
            preciosoporte=precioservicios*0.02
          end
        end

        if type=="premium"
          if precioservicios<100000
            preciosoporte=10000
          end
          if precioservicios>=100000 and precioservicios <500000
            preciosoporte=precioservicios*0.06
          end
          if precioservicios>=500000 and precioservicios <1000000
            preciosoporte=precioservicios*0.04
          end
          if precioservicios>=1000000
            preciosoporte=precioservicios*0.03
          end
        end

        resultado={ type: type, precio: preciosoporte.round(2).to_f, precioservicios:precioservicios}
        logger.info(resultado.to_s)
      rescue PG::Error => e
        logger.info(e.message.to_s)
      end
      resultado.to_json
  end
####################################################################
#
# Servicios para dimensionamiento de clúster OCP
#
####################################################################
get '/sizingclusteroptimoproductivo' do
  logger = Logger.new(STDOUT)
  cpu="#{params['cpu']}".to_f+2
  ram="#{params['ram']}".to_f+8
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

get '/sizingclusterproductivo' do
  logger = Logger.new(STDOUT)
  cpu="#{params['cpu']}".to_f+2
  ram="#{params['ram']}".to_f+8
  resultado=[]
  begin
    connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
    t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1 as workers, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_wo_subs precio, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_w_subs precio_subs from public.ocp_classic_flavors where (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)>=2 order by precio asc"
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


  get '/sizingclusteroptimo' do
    logger = Logger.new(STDOUT)
    cpu="#{params['cpu']}".to_f+2
    ram="#{params['ram']}".to_f+8
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
    cpu="#{params['cpu']}".to_f+2
    ram="#{params['ram']}".to_f+8
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

  get '/preciocluster' do
    logger = Logger.new(STDOUT)
    wn="#{params['wn']}"
    flavor="#{params['flavor']}"
    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type,#{params['wn']} as workers, #{params['wn']}*price_w_subs precio, #{params['wn']}*price_wo_subs precio_wo_subs, region from public.ocp_classic_flavors where infra_type='#{infra_type}' and region='#{region}' and flavor='#{flavor}' order by precio asc LIMIT 1"
      t_messages.each do |s_message|
          resultado.push({ flavor: s_message['flavor'], infra_type: s_message['infra_type'], workers: s_message['workers'], precio: s_message['precio'].to_f,precio_wo_subs: s_message['precio_wo_subs'].to_f, region: s_message['region'] })
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
  # Servicios para dimensionamiento para Veeam
  #
  ####################################################################

  
  get '/volumenrespaldosveeam' do
    logger = Logger.new(STDOUT)
    almacenamientogb="#{params['almacenamientogb']}"
    #parametros de politicas
    rsemanal="#{params['rsemanal']}"
    rsemanalretencion="#{params['rsemanalretencion']}" #cantidad de backups retenidos
    rdiario="#{params['rdiario']}"
    rdiarioretencion="#{params['rdiarioretencion']}"#incrementales diarios
    rmensual="#{params['rmensual']}"
    rmensualretencion="#{params['rmensualretencion']}"#cantidad de backups retenidos
    rmensual="#{params['ranual']}"
    rmensualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    ranual="#{params['ranual']}"
    ranualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    diff="#{params['diff']}"
    ratiocompresion=2 
    volumentotal=0
    volumentotalcomprimido=0
    resultado=[]
    begin
      logger.info("calculando almacenamiento")
      if rsemanal
        vol=almacenamientogb.to_f*rsemanalretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rdiario
        vol=almacenamientogb.to_f*(diff/100)*rdiarioretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rmensual
        vol=almacenamientogb.to_f*rmensualretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if ranual
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



  ####################################################################
  #
  # Servicios para dimensionamiento para PX-backup
  #
  ####################################################################

  get '/volumenrespaldospxbackup_w_pxenterprise' do
    logger = Logger.new(STDOUT)
    almacenamientogb="#{params['almacenamientogb']}"
    #parametros de politicas
    rsemanal="#{params['rsemanal']}"
    rsemanalretencion="#{params['rsemanalretencion']}" #cantidad de backups retenidos
    rdiario="#{params['rdiario']}"
    rdiarioretencion="#{params['rdiarioretencion']}"#incrementales diarios
    rmensual="#{params['rmensual']}"
    rmensualretencion="#{params['rmensualretencion']}"#cantidad de backups retenidos
    rmensual="#{params['ranual']}"
    rmensualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    ranual="#{params['ranual']}"
    ranualretencion="#{params['ranualretencion']}"#cantidad de backups retenidos
    diff="#{params['diff']}".to_i
    ratiocompresion=2.5 #algoritmo de compresion LZ77
    volumentotal=0
    volumentotalcomprimido=0
    resultado=[]
    begin
      logger.info("calculando almacenamiento")
      if rsemanal
        vol=almacenamientogb.to_f*rsemanalretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rdiario
        vol=almacenamientogb.to_f*(diff/100)*rdiarioretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rmensual
        vol=almacenamientogb.to_f*rmensualretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if ranual
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
      if rsemanal
        vol=almacenamientogb.to_f*rsemanalretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rdiario
        vol=almacenamientogb.to_f*rdiarioretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if rmensual
        vol=almacenamientogb.to_f*rmensualretencion.to_i
        logger.info("volumen semanal (GB):"+vol.to_s)
        volumentotal=volumentotal+vol
        resultado={ volumentotal: volumentotal}
      end
      if ranual
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
      resultado={ workers: workers, precio: precio.round(2).to_f}
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
    cpu="#{params['cpu']}".to_f+1
    ram="#{params['ram']}".to_f+2
    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price precio from public.iks_classic_flavors where infra_type='#{infra_type}' and region='#{region}' order by precio asc LIMIT 1"
      t_messages.each do |s_message|
          resultado.push({ flavor: s_message['flavor'], infra_type: s_message['infra_type'], workers: s_message['workers'], precio: s_message['precio'].to_f })
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
          resultado.push({ flavor: s_message['flavor'], infra_type: s_message['infra_type'], workers: s_message['workers'], precio: s_message['precio'].to_f, region: s_message['region'] })
      end
      logger.info(resultado.to_s)
    rescue PG::Error => e
      logger.info(e.message.to_s)
    ensure
      connection.close if connection
    end
    resultado.to_json
  end

  get '/ikssizingcluster' do
    logger = Logger.new(STDOUT)
    cpu="#{params['cpu']}".to_f+1
    ram="#{params['ram']}".to_f+2
    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price precio from public.iks_classic_flavors where infra_type='#{infra_type}' and region='#{region}' order by precio asc"
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
        resultado={precio: (resultado1+resultado2+resultado3).round(2), "nota": "El precio para algunos escenarios puede varias 10%, valida en cloud.ibm.com. Ingresa los siguientes valores: Pais:#{country} Tipo de storage:#{service_type} region:#{region} resiliencia:#{resiliency} storage:#{storage} retrival:#{retrival} publicoutbound:#{publicoutbound} Op A:#{opa} Op B:#{opb} "}
        logger.info("precio: "+resultado.to_s)
        resultado.to_json
      end
end

####################################################################
#
# API Versión 2
#
####################################################################

namespace '/api/v2' do
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
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio asc LIMIT 1"
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
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio asc"
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

  get '/sizingclusteroptimoproductivo' do
    logger = Logger.new(STDOUT)
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1) as workers, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_wo_subs precio, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_w_subs precio_subs from public.ocp_classic_flavors where (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio asc LIMIT 1"
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

  get '/sizingclusterproductivo' do
    logger = Logger.new(STDOUT)
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, (infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1) as workers, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_wo_subs precio, (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)*price_w_subs precio_subs from public.ocp_classic_flavors where (greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))+1)>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio asc"
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

          

  get '/sizingclusteroptimosubs' do
    logger = Logger.new(STDOUT)
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio_subs asc LIMIT 1"
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

  get '/sizingclustersubs' do
    logger = Logger.new(STDOUT)
    cpu_aux="#{params['cpu']}".to_f+2
    ram_aux="#{params['ram']}".to_f+8

    if cpu_aux <= 4 || ram_aux <= 16
      cpu = 5
      ram = 17
    else
      cpu = cpu_aux
      ram = ram_aux
    end

    infra_type="#{params['infra_type']}"
    region="#{params['region']}"
    resultado=[]
    begin
      connection = PG.connect :dbname => 'ibmclouddb', :host => '313a3aa9-6e5d-4e96-8447-7f2846317252.0135ec03d5bf43b196433793c98e8bd5.databases.appdomain.cloud',:user => 'ibm_cloud_31bf8a1b_1bbe_49e4_8dc2_0df605f5f88b', :port=>31184, :password => '535377ecca248285821949f6c71887d73a098f00b6908a645191503ab1d72fb3'
      t_messages = connection.exec "select flavor, infra_type, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb)) as workers, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_wo_subs precio, greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))*price_w_subs precio_subs from public.ocp_classic_flavors where greatest(ceil(#{cpu}/cpu),ceil(#{ram}/ram_gb))>=2 and infra_type='#{infra_type}' and region='#{region}' order by precio_subs asc"
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
end
