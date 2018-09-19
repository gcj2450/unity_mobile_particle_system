Shader "Unlit/NewUnlitShader"
{
	Properties
	{
		_MainTex ("My Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex   : POSITION;
			    uint vid        : SV_VertexID;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				float4 col      : COLOR;
				float pointSize : PSIZE;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				v.vertex.xyz += v.vid + .2f;
				o.vertex      = UnityObjectToClipPos(v.vertex);
				o.col         = fixed4(v.vid, v.vid, v.vid, 1.f);
				o.pointSize   = 10.f;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = fixed4(1.f, 0.f, 1.f, 1.f);
				return i.col;
			}
			ENDCG
		}
	}
}
