/*
Email: Gforcex@163.com
Github: https://github.com/Gforcex
*/

Shader "Shading/LightingModel" {
	Properties
	{
		[Toggle(_WS_SPECULAR)] _WorkSpace ("Specular WorkSpace", Float) = 0
				
		//[KeywordEnum(_BRDF_Disney, _BRDF_Cooktorrance, _BRDF_Phong , _BRDF_Blinnphong, _BRDF_Modifiedphong, _BRDF_Stretchedphong, _BRDF_Blinn, _BRDF_Walter, _BRDF_Edwards , _BRDF_Strauss,_BRDF_WardIsotropic, _BRDF_WardAnispotropic, _BRDF_Kajiya, _BRDF_DisneyAniso , _BRDF_AshikhmanShirley  )] 
		//_BRDFMode ("BRDF Mode", Float) = 0

		[Header(Base)]
		_Color("Albedo Color", Color) = (0, 0, 0, 1.0)
		_MainTex ("Albedo Map", 2D) = "white" {}
		_NormalTex ("Normal Map", 2D) = "bump" {}
		_SpecularTex ("Specular Map", 2D) = "white" {}
		_MetallicTex ("Metallic Map", 2D) = "white" {}
		_RoughnessTex ("Roughness Map", 2D) = "white" {}
		_AnisotropicTex ("Anisotropic Map", 2D) = "white" {}
		
		_SubsurfaceColor("Subsurface Color", Color) = (0, 0, 0, 1.0)
		_Roughness("Roughness", Range(0.0, 1.0)) = 0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0

		[Header(Anisotropic)]
		_Anisotropic("Anisotropic", Range(0.0, 1.0)) = 0
		_Anisotropic2("Anisotropic 2", Range(0.0, 1.0)) = 0

		[Header(Disney)]
		_SpecularTint("SpecularTint", Range(0.0, 1.0)) = 1
		_Specular("Specular", Range(0.0, 1.0)) = 1
		_SheenTint("SheenTint", Range(0.0, 1.0)) = 0
		_Sheen("Sheen", Range(0.0, 1.0)) = 0
		_ClearcoatGloss("ClearcoatGloss", Range(0.0, 1.0)) = 0
		_Clearcoat("Clearcoat", Range(0.0, 1.0)) = 0
		_Subsurface("Subsurface", Range(0.0, 1.0)) = 0

		[Header(Ambient)]
		_EnvMap ("Env Map", CUBE) = "black" {}
		_IrradianceMap ("Irradiance Map", CUBE) = "black" {}
		_IndirectSpecularIntensity("Indirect Specular Intensity", Range(0.0, 2.0)) = 0
		_IndirectDiffuseIntensity("Indirect Diffuse Intensity", Range(0.0, 2.0)) = 0

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
		[HideInInspector] _CullMode ("__cull", Float) = 2.0
		[HideInInspector] _BRDFMode ("__brdf", Float) = 0
	}

    SubShader {
		Tags { "RenderType"="Opaque" }

        Pass {

			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag	
			#pragma target 3.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile _ _ALPHABLEND_ON
			#pragma multi_compile _ _ALPHATEST_ON 
			#pragma shader_feature _ _WS_SPECULAR

			#pragma shader_feature _BRDF_Disney
			#pragma shader_feature _BRDF_Phong
			#pragma shader_feature _BRDF_Blinnphong
			#pragma shader_feature _BRDF_Modifiedphong
			#pragma shader_feature _BRDF_Stretchedphong
			#pragma shader_feature _BRDF_Blinn
			#pragma shader_feature _BRDF_Cooktorrance
			#pragma shader_feature _BRDF_DisneyAniso
			#pragma shader_feature _BRDF_Kajiya
			#pragma shader_feature _BRDF_AshikhmanShirley
			#pragma shader_feature _BRDF_Walter
			#pragma shader_feature _BRDF_Ward
			#pragma shader_feature _BRDF_WardIsotropic
			#pragma shader_feature _BRDF_Edwards
			#pragma shader_feature _BRDF_Strauss
			#pragma shader_feature _BRDF_ClothAshikhmin
			#pragma shader_feature _BRDF_ClothCharlie
			#pragma shader_feature _BRDF_ClothUE4

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "BRDF.cginc"
			#include "DiffuseBRDF.cginc"
            #include "DisneyBRDF.cginc"
			#include "CookTorranceBRDF.cginc"
			#include "ClothBRDF.cginc"
			#include "ClearCoatBRDF.cginc"
			#include "LightingModel.cginc"

			#define _NORMALMAP 1
            
            sampler2D _MainTex;
            sampler2D _NormalTex;
			sampler2D _MetallicTex;
			sampler2D _SpecularTex;
			sampler2D _RoughnessTex;
			sampler2D _AnisotropicTex;

			samplerCUBE _EnvMap;
			samplerCUBE _IrradianceMap;
			
			half3 _SubsurfaceColor;
			half _Roughness;
			half _Metallic;
			float4 _Color;
			half _SpecularTint;
			half _Specular;
			half _SheenTint;
			half _Sheen;
			half _Anisotropic;
			half _Anisotropic2;
			half _ClearcoatGloss;
			half _Clearcoat;
			half _Subsurface;
			
			half _IndirectSpecularIntensity;
			half _IndirectDiffuseIntensity;

            uniform float4 _LightColor0;
			
            struct vertexIn {
                float4 vertex	 : POSITION;
                float4 texcoord  : TEXCOORD0;
                half3  normal	 : NORMAL;
                float4 tangent	 : TANGENT;
            };

            struct v2f {
                float4 pos			 : SV_POSITION;
                float4 texcoord		 : TEXCOORD0;
                float4 tangentW		 : TEXCOORD1;  
         		float4 normalW		 : TEXCOORD2;
         		float4 binormalW	 : TEXCOORD3;

				UNITY_FOG_COORDS(4)
				SHADOW_COORDS(5)
            };

            v2f vert(vertexIn v)
            {
                v2f o;
                
                o.pos = UnityObjectToClipPos (v.vertex);
                o.texcoord = v.texcoord;
                
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normalW = float4( UnityObjectToWorldNormal(v.normal), worldPos.x );

				float  tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				o.tangentW = float4(UnityObjectToWorldDir(v.tangent.xyz), worldPos.y);
				o.binormalW = float4(cross(o.normalW.xyz, o.tangentW.xyz) * tangentSign, worldPos.z);

				TRANSFER_SHADOW(o);				  // pass shadow coordinates to pixel shader
				UNITY_TRANSFER_FOG(o,o.pos);	  // pass fog coordinates to pixel shader
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
				//------------------------------------------------------------------------------------------

				half3 worldPos = half3( i.normalW.w, i.tangentW.w, i.binormalW.w );
				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); 
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				i.normalW.xyz = normalize(i.normalW.xyz); 
				#ifdef _NORMALMAP
					half3 normal = UnpackNormal(tex2D (_NormalTex, i.texcoord));
					normal = i.tangentW.xyz * normal.x + i.binormalW.xyz * normal.y + i.normalW.xyz * normal.z;
					normal = normalize( normal );
				#else
					half3 normal = i.normalW.xyz;
				#endif
			
				half3 viewDir = normalize( UnityWorldSpaceViewDir(worldPos) );
				half3 halfView = normalize( viewDir + lightDir );
				half3 viewRefl = reflect(-viewDir, normal);

				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
				half3 lightColor = _LightColor0.rgb * atten;
				//------------------------------------------------------------------------------------------

            	float4 baseColor = tex2D(_MainTex, i.texcoord);
				baseColor.rgb *= _Color;

				half Roughness = tex2D(_RoughnessTex, i.texcoord).x * _Roughness;									
	    
				half dielectric = 0.04;
			#ifdef _WS_SPECULAR
    			half3 diffColor = baseColor.rgb;
    			half3 specColor = tex2D(_SpecularTex, i.texcoord).rgb;
				half metallic = (specColor - dielectric.xxx) / (baseColor.rgb - dielectric.xxx);				
			#else
				half metallic = tex2D(_MetallicTex, i.texcoord).x * _Metallic;
			    half3 diffColor = baseColor.rgb - baseColor.rgb * metallic;
    			half3 specColor = dielectric + (baseColor.rgb - dielectric) * metallic;
			#endif 
	
				half3 X = i.tangentW.xyz;
				half3 Y = i.binormalW.xyz;				
				half transparency = baseColor.a;
							
				half2 AnisoRoughness =  tex2D(_AnisotropicTex, i.texcoord).rg * half2(_Anisotropic, _Anisotropic2);
				half anisotropic = AnisoRoughness.x;

				half specularTint = _SpecularTint;
				half specular = _Specular;
				half sheenTint = _SheenTint;
				half sheen = _Sheen;
				half clearcoatGloss = _ClearcoatGloss;
				half clearcoat = _Clearcoat;
				half subsurface = _Subsurface;
				//------------------------------------------------------------------------------------------
		//		#define _BRDF_Disney
		//		#define _BRDF_Phong
		//		#define _BRDF_Blinnphong
		//		#define _BRDF_Modifiedphong
		//		#define _BRDF_Stretchedphong
		//		#define _BRDF_Blinn
		//		#define _BRDF_Cooktorrance
		//		#define _BRDF_DisneyAniso
		//		#define _BRDF_Kajiya
		//		#define _BRDF_AshikhmanShirley
		//		#define _BRDF_Walter
		//		#define _BRDF_Ward
		//		#define _BRDF_WardIsotropic
		//		#define _BRDF_Edwards
		//		#define _BRDF_Strauss

				half NoL = max(0, dot(normal, lightDir));
				half3 brdf = 0;
			#if defined(_BRDF_Disney)
				#define _DIFFUSE
				brdf = brdfDisney(baseColor.rgb, Roughness, metallic, 
								  specularTint, specular, sheenTint,sheen, 
								  anisotropic, clearcoatGloss, clearcoat, subsurface, 
								  normal, lightDir, viewDir, i.tangentW, i.binormalW, diffColor, specColor);
			#elif defined(_BRDF_Phong)
				brdf = brdfPhong(specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_Blinnphong)
				brdf = brdfBlinnphong(specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_Modifiedphong)
				brdf = brdfModifiedphong(specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_Stretchedphong)
				brdf = brdfStretchedphong( specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_Blinn)
				brdf = brdfBlinn(specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_Cooktorrance)
				brdf = brdfCooktorrance( specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_DisneyAniso)
				brdf = brdfDisneyAniso( specColor, lightDir, viewDir, normal, X, Y, Roughness);
			#elif defined(_BRDF_Kajiya)
				brdf = brdfKajiya( specColor, lightDir, viewDir, normal, X, Y, Roughness);
			#elif defined(_BRDF_AshikhmanShirley)
				#define _DIFFUSE
				brdf = brdfAshikhmanShirley( diffColor, specColor, lightDir, viewDir, normal, X, Y , AnisoRoughness);
			#elif defined(_BRDF_Walter)
				brdf = brdfWalter( specColor, lightDir, viewDir, normal, X, Y , Roughness);
			#elif defined(_BRDF_Ward)
				brdf = brdfWard( specColor, lightDir, viewDir, normal, X, Y, AnisoRoughness);
			#elif defined(_BRDF_WardIsotropic)
				brdf = brdfWardIsotropic( normal, viewDir, lightDir, Roughness) ;
			#elif defined(_BRDF_Edwards)
				brdf = brdfEdwards( specColor, lightDir, viewDir, normal, X, Y, AnisoRoughness);
			#elif defined(_BRDF_Strauss)
				#define _DIFFUSE
				brdf = brdfStrauss( diffColor, normal, viewDir, lightDir, Roughness, metallic , transparency);
			#elif defined(_BRDF_ClothAshikhmin)
				#define _DIFFUSE
				brdf = brdfClothAshikhmin(diffColor, _SubsurfaceColor, specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_ClothCharlie)
				#define _DIFFUSE
				brdf = brdfClothCharlie(diffColor, _SubsurfaceColor, specColor, lightDir, viewDir, normal, Roughness);
			#elif defined(_BRDF_ClothUE4)
				#define _DIFFUSE
				brdf = brdfClothUE4(diffColor, _SubsurfaceColor, 0.5, specColor, lightDir, viewDir, normal, Roughness);
			#endif

				//------------------------------------------------------------------------------------------
				half mipIndex =  Roughness * Roughness * 8.0f;
			    half3 envColor = texCUBElod(_EnvMap, half4(viewRefl,mipIndex )).rgb;
					  envColor *= Item_F(specColor, saturate(dot(viewDir, halfView)));
			    half3 irradianceColor = texCUBE(_IrradianceMap, normal).rgb;
					  irradianceColor *= diffColor;
				//------------------------------------------------------------------------------------------
				float4 col = 0;
			#ifndef _DIFFUSE
				col.rgb += diffColor * lightColor * NoL;
			#endif
				col.rgb += brdf * lightColor;
				col.rgb += envColor * _IndirectSpecularIntensity;
				col.rgb +=  irradianceColor * _IndirectDiffuseIntensity;
				col.a = baseColor.a;

				UNITY_APPLY_FOG(i.fogCoord, col);	
				return col;
            }
            
            ENDCG
        }
    }
	CustomEditor "LightingModelGUI"
}
